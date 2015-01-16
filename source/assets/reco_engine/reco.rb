module Reco

  # will recommend artists to a user
  def recommendations

    # fetch my list of liked artists. We only need their id and liker_ids (not the name, nor anything else)
    my_artists = liked_artists.only(:id, :liker_ids)

    # fetch my list of 'friends'. Again, we only need id and liked_artist_ids :
    friends = User.any_in(id: my_artists.distinct(:liker_ids)).only(:id, :liked_artist_ids)

    # Initialize the result:
    reco = Hash.new(0)

    # Let's roll
    friends.each do |friend|

      # the number of liked artists we share:
      in_common = (friend.liked_artist_ids & self.liked_artist_ids)

      # The friend's weight:
      w = in_common.size.to_f / friend.liked_artist_ids.size

      # Add the recommendations:
      ( friend.liked_artist_ids - in_common).each do |artist_id|
        reco[artist_id] += w
      end

    end

    # find artist names, sort and return in a pretty format:
    Artist.any_in(id: reco.keys)
    .only(:id, :name)                 #only name and id here
    .sort_by{|a| reco[a.id]}          #sort by our reco results
    .reverse                          # higher score first
    .map{|a| [a,reco[a.id].round(2)]} # associate record with its score

  end


end
