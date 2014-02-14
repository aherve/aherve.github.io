---
layout: post
title: "We should fix the physics engine"
date: 2014-02-13 16:54:23 +0100
comments: true
categories: 
 - physics
---

I think the Universe's laws of physics are now way outdated. Let's suggest a patch for this.

`Universe::Physics` v 2.1.0 release notes

- **Quantum tunnel glitch** : fixed a bug that randomly caused particles to go through well potentials although they lacked the energy to do it.
- **High velocity engine improved** : heavy computations at high speed caused local space-time to bend. The engine is now better and the so-called relativistic effects are now minimized.
- **Improved data structure (Heisenberg's bug)**: Variables are stored with more efficiency. It is now possible to know both where a particle is, and at what speed it travels.
<!-- more -->
- **Entropy leak**: Some memory leaks that caused entropy to constantly grow without limit have been fixed.
- **Teleportation**: Owing to some pointer error, changing the spin of some particle would instantly affect its twin particle in some setups. This is no longer the case.
- **Planck's constant**: A better meshing takes place, and the Planck's constant has been drastically reduced so the universe seems more "continuous".
- **Electrons**: For the sake of simplicity, electrons now actually rotate around the atoms.
- **Pi number**: It seems the ratio between a circle diameter and its circumference has attracted a lot of attention during the last two millenniums. For more convenience, it has been set to an exact --rational-- value of `pi= 3.14`.

Any further suggestions will be welcomed !
