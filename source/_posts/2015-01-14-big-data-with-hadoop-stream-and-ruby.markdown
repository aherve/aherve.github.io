---
layout: post
title: "Big data with hadoop stream and ruby (and not even one line of java)"
date: 2015-01-14 13:42:09 +0100
comments: true
categories: 
 - ruby
 - hadoop
 - big data
 - elastic mapreduce
 - mapreduce
 - tutorial
---

### Objective: 

In this tuto I'll show you how to process billions of data with minimal efforts and code with elastic mapreduce and hadoop-stream. Our list to Santa is : 

 - I want to process an unknown amount of data in a scalable, custom way
 - The same code can be run locally and remotely, so I can debug or process any amount of data without changing anything
 - I should be able to use any language I like, and this does not especially have to be java. In this example I'll be using ruby because it's awesome. Simply translate this tuto to python, perl, php or anything you want, it'll still work.

<!-- more -->
## 1. Let's play a game

Let's suppose we are running a huge gaming platform. As the brand new data scientist, we're asked to perform some simple stats on our users.

For the sake of the example, let's compute any user's average ranking, per type of played games.

From the platform logs we have to kind of files:

 - a `GameLog` file describes the type of game, the date, and a game id
 - a `PlayerLog` file describes how a player scored a game. It contains the game id, the player id, and the player score.

This looks like

```ruby PlayerLog
PlayerId    Score    GameId    
1           1       1         
1           2       2         
2           0       1         
2           5       2         
```

```ruby GameLog
GameId    Type 
1         chess
2         go   
```

Our files are tab separated (tsv) format, and stored on an amazon [aws s3](https://aws.amazon.com/s3/) bucket.

#### Expected output:

```ruby Output
Player_id    GameType    AverageRank
1            chess       1
1            go          2
2            chess       2
2            go          1
```

## 2. Do this with style !

We are going to solve this algorithm with mapreduce. Map/reduce is a programming paradigm that will allow you to _horizontally scale_ the program execution. This means the more parallel servers you get, the more efficient you will be. Obviously within a reasonable range, mounting 300 servers to process 10 lines of data doesn't look like a good idea..

In addition to be scalable, I really find a map/reduce reduces the amount of code, increases claricity, and should thus be used even for moderate amount of datas.

__Bonus:__ We'll be able to run our code both locally for quick tests, and remotely for heavy processing \o/

#### The approach

Before entering in the details, here is what we are going to do:
 
 - map the raw data and extract useful information (map)
 - group the data by `game_id` key (sort)
 - compute each player rank for each game (reduce1)
 - group the data by (player,game_type) couples (sort)
 - for each (player/game_type) couple, compute the average rank (reduce2)

Our steps hence consists in a _map -> reduce -> reduce_ procedure. If we think of a second mapper which is identity, then we have two `map->reduce` steps

As we plan to use hadoop-stream, the only things we need are three script files that will represent our mapper, and reducers. Each file will consist of a simple script that will "eat" data via `STDIN`, and output something to `STDOUT`.
Again, I'm using ruby as an example here. If you're more comfortable with any other language, then please use it, as long as it knows `STDIN` and `STDOUT` !

Thanks to Hadoop, we won't have to take care of the sort steps, the data redundency management, the possible server crashes, and plenty of boring stuff. How nice is that ? 

### 2.1. first mapper

The first mapper's role will be to "eat" raw data with absolutely no context, nor any knowledge of what's happening elsewhere (_i.e._ on other potential workers). It is very important to note that there is absolutely no relation between two consecutive lines that a mapper receives.
For instance, some mapper could receive the first line of the first log, then the 10th line of another log file, then the 2nd line of the first log...etc


```ruby map1.rb
#!/usr/bin/env ruby

class Mapper

  # initialize a mapper with raw data.
  def initialize(line)
    # chomp will remove endline characters
    # split will split the line for every tab character \t
    # strip will remove whitespaces at begining and end of every words
    @data = line.chomp.split("\t").map(&:strip)
  end

  # this "switch" will determine if we are reading a GameLog or a UserLog line
  # in our example, it is sufficient to look whether @data has 2, or 3 values
  # for more complex cases, I'm sure you'll always find something ;)
  def log_type
    @log_type ||= if @data.size == 2
                :game_log
              else
                :player_log
              end
  end

  def game_log_output
    game_id   = @data[0]
    game_type = @data[1]

    [game_id, log_type, game_type].join("\t")
  end

  def player_log_output
    player_id = @data[0]
    score     = @data[1]
    game_id   = @data[2]

    [game_id, log_type, player_id, score].join("\t")
  end

  # the mapper result
  def output
    return game_log_output if log_type == :game_log
    return player_log_output
  end

  # the Map! class method
  def self.map!(line)
    puts Mapper.new(line).output
  end

end

ARGF.each do |line|
  Mapper.map!(line) unless line.chomp.empty? # map every non-empty line with our mapper
end
```

As you can see, this mapper will always output the `game_id` as first key. Then, regarding of the log type, it will either output informations about the player, or the game.

You can run locally your mapper by simply running `cat datain/* | map1.rb`, whitch outputs something like

```ruby
1 player_log  1 1
2 player_log  1 2
1 player_log  2 0
2 player_log  2 5
1 game_log  chess
2 game_log  go
```

### 2.2 first sort


I feel like this step should be explained even if it does not require any work. What will be happening here is that hadoop will take care of our first outputed results.
By default, it will split using the `tab` character, and will assign a single reducer instance for each key.
Furthermore, it will garanty that a reducer will see 'sorted' results

This step is very important to understand. It means two things for the reducer:

 - For each primary key (`game_id` in our example), all the corresponding lines will be sent to the same reducer instance. This allows to process data without any communication between the reducers.
 - The data is sorted. This implies that if a reducer sees a `game_id=1` key, then all following lines will also be `game_id=1` until there is no `game_id=1` key left. Ever. As soon a the reducer receives a different primary key, then we can assume __all__ the `game_id=1` lines have been processed.

#### When running with bash: 

As I said, I should be able to run my code both locally and remotely. Fortunately, we can perform a sort with bash with the `sort` command.

This trick consists of performing a pure sort on the data. When running locally, we don't have to distribute the data between different instances (which hadoop does) so a sorted data will garanty the two features that we require for our reducer.

running this in bash would yield:

`cat datain/* | map1.rb | sort` =>
```ruby
1 game_log  chess
1 player_log  1 1
1 player_log  2 0
2 game_log  go
2 player_log  1 2
2 player_log  2 5
```

As you can see, the data is now grouped by `game_id` key. How delightful.

#### When running with hadoop: 

Simply perform some cool dance moves while hadoop take care of everything.

{% img center /images/success_dance.gif %}


### 2.3 first reduce

The first reducer will accumulate the player scores, in order to determine the players ranks in each played game:
```ruby reduce1.rb
#!/usr/bin/env ruby

class Reducer

  attr_accessor :key, :game_type

  def initialize(key)
    @key = key
    @player_scores = Hash.new
  end

  def accumulate(splitted_line)
    if splitted_line[1] == 'game_log' #if the line is of type game_log
      @game_type = splitted_line[2]
    else # if the line is of type player_log
      player_id = splitted_line[2]
      player_score = splitted_line[3]

      @player_scores[player_id] = player_score
    end
  end

  def output!
    ordered_player_ids.each_with_index do |id,i|
      puts [
        "#{@game_type}|#{id}", # joined to form a new key for the next reducer
        i+1 #the rank (+1 so the first has a rank of 1)
      ].join("\t")
    end
  end

  def ordered_player_ids
    # this will output a list of player_ids, sorted by their scores
    # Note that I'm way too lazy to deal with draws here :D
    @player_scores.sort_by{|player,score| score}.reverse.map(&:first)
  end

end


ARGF.each do |line|
  # split the data
  splitted_line = line.chomp.split("\t").map(&:strip)

  # get the primary key
  new_key = splitted_line.first

  #initialize if required
  @red ||= Reducer.new(new_key)

  # if the key is the same, then continue accumulating
  if new_key == @red.key
    @red.accumulate(splitted_line)

    # if the key is new, then first output current results, then instanciate a new reducer
    # Note that once the result is outputed to STDOUT, we can drop the reducer instance
  else
    @red.output! unless @red.key.nil?
    @red = Reducer.new(new_key)
    @red.accumulate(splitted_line)
  end
end
@red.output!
```

Now our process yield `cat datain.dat | ./map1.rb | sort | ./reduce1.rb ` =>

```ruby
chess|1 1
chess|2 2
go|1    2
go|2    1
```

This could be read as

 - _player 1 scored one chess game with rank 1_
 - _player 2 scored one chess game with rank 2_
 - _player 1 scored one go game with rank 2_
 - _player 2 scored one go game with rank 1_

Please note something very important here: __The reducer stores almost nothing in memory!__
As you can see in the script, as soon as a game is finished processing, then we can simply output the result and drop our reducer. Nothing has to stay in memory, so you don't need any ram on your workers, even to process billions of games !

###2.4. coffe break !

{% img center /images/coffe-break.gif %}

If you're still reading this then I'm sure you deserve it.

### 2.5. Second mapper
Nothing has to be done here, the data is already formated for the next reduce step.

Conceptualy, we can view this step as a map step, where the mapper would be identity.
As a reminder that something is still hapening here, I'll pipe the unix `cat` command to our workflow. Of course it has no practical purpose.

When running our code with hadoop-stream, we'll declare a `map` step, with identity mapper ( or we'll simply declare `cat` to be our mapper script, which is pretty much the same)

### 2.6 Last step: averaging the scores

For the sake of the argument, let's say I wasn't this lazy, and generated much more data, which led to a `reduce1` output that reads

```ruby
chess|1 1
chess|1 1
chess|2 1
chess|2 2
go|1    2
chess|1 1
go|1    1
go|1    1
chess|2 2
go|1    1
go|1    2
hide-and-seek|1 8
go|2    1
go|2    1
hide-and-seek|3 2
hide-and-seek|1 8
chess|1 1
hide-and-seek|1 8
chess|1 2
hide-and-seek|3 5
hide-and-seek|3 1
```

We now have three players, three different games. I also shuffled the results, to emphasis that the reduce step does not necessary provide sorted results.
Actually it does when running our _bash workflow_, since we're using `sort` and a single proc. Generally speaking it is not.

Once we run the identity mapper, followed by the sort step, it will again be sorted so we can write our final reducer as follows:


```ruby reduce2.rb
#!/usr/bin/env ruby

class Reducer

  attr_accessor :key, :game_type, :user_id

  def initialize(key,value)
    @key = key

    #split the primary key to get user_id and game type:
    @game_type,@user_id = key.split("|")

    #to perform an on-the-fly average, we only need two variables:
    @count = 1
    @average = value.to_f
  end

  #on the fly averaging. We do NOT store the entire array !
  def accumulate(value)
    @average  = ( @count.to_f/(@count + 1) * @average ) + (value.to_f / (@count + 1) )
    @count += 1
  end

  # follow the expectations
  def output!
    puts [
      @user_id,
      @game_type,
      @average.round(1),
    ].join("\t")
  end

end


ARGF.each do |line|
  next if line.chomp.empty?

  # split the data
  new_key,value = line.chomp.split("\t").map(&:strip)

  #initialize if required
  @red ||= Reducer.new(new_key,value)

  # if the key is the same, then continue accumulating
  if new_key == @red.key
    @red.accumulate(value)

  # if the key is new, then first output current results, then instanciate a new reducer
  else
    @red.output! 
    @red = Reducer.new(new_key,value)
  end
end
@red.output!
```

If we run our bash process we get `cat datain/* | ./map1.rb | sort | ./reduce1.rb | cat | sort | ./reduce2.rb` (assuming we have our new dataset):

```ruby
1 chess 1.2
2 chess 1.7
1 go  1.4
2 go  1.0
1 hide-and-seek 8.0
3 hide-and-seek 2.7
```

And that's it ! we know knows that the player 1 performed an average rank of 1.2 at chess, and an average rank of 8.0 at hide and seek !

## 3. Going heavy

Like I told you, our script are hadoop-ready. Provided you have an aws-amazon account, running our code can be done very easily:

 - install amazon elastic-mapreduce client and configure it (basically give it your credentials)
 - run the first map-reduce stage: 

```bash elastic_mapreduce_launcher_stage1.sh
elastic-mapreduce \
  --create \
  --name look_mom_big_data \
  --stream \
  --input s3n://yourbucket/data_in \
  --mapper s3n://yourbucket/src/map1.rb \
  --reducer s3n://yourbucket/src/reduce1.rb \
  --output s3n://yourbucket/first_results \
  --log-uri s3://yourbucket/emr-logs/ \
  --region eu-west-1 \
  --instance-type m1.small \
  --num-instances 300
```

then 

```bash elastic_mapreduce_launcher2.sh
elastic-mapreduce \
  --create \
  --name look_mom_big_data \
  --stream \
  --input s3n://yourbucket/first_results \
  --mapper cat \
  --reducer s3n://yourbucket/src/reduce2.rb \
  --output s3n://yourbucket/output \
  --log-uri s3://yourbucket/emr-logs/ \
  --region eu-west-1 \
  --instance-type m1.small \
  --num-instances 300
```

Note that I'm using two different launchers here. You can also tell your launcher to perform multiple steps by passing them as json. See the elastic-mapreduce doc for that.

_Wait... Is it this simple?_

Yes. This simple.

## Conclusion

Thanks for reading, you're awesome

{% img center /images/not_impressed.gif %}

If this helped you in any way, feel free to drop a comment, correct something, ask a question, or simply let me know this was interesting, thanks !

Please note that this approach can be -- and have been -- used for heavy industrial purposes. You can litterally process billions of rows in no time, with a few lines of code. This is, in my opinion, a tremendous way to prototype and scale your data analysis !
