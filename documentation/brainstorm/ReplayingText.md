Once we have a data structure representing every single change made and the
times in between changes, we'll be able to reconstruct everything typed in
realtime, as if the person were typing it again.

Playback should have more features than realtime though, as you could end up
waiting a very long time!

Here's some things I've thought of so far:

* A slider showing the progress through the animation, which can be adjusted to jump ahead or backwards (or paused).
    * The slider should give different types of (optional) information, such as time remaining, the current change-index, the percentage completion.
* Controls to speed up or slow down playback, which will just scale the timestamps associated with each node in the diff structure by some constant factor.
* A threshold time for the longest you want to wait for any real-time change.
    * If this threshold is set, optionally display via pop-up boxes that fade away or some other element, the real-time elapsed between any change made. So, for example, if I set the threshold to 5 seconds, and the animation isn't updated for 3 minutes, 14 seconds, I want a little fading popup showing something like "3 minutes and 14 seconds later...", or whatever.


An other interesting feature would be to offer custom editing that exposes the underlying data structure (wrapped in a much nicer interface), giving users the ability to artificiate a text, and give it the feeling of being typed in real time. I see this is being something that can be used by people to write stories / interactive experiences. Inspiration could be drawn from http://www.mattboldt.com/demos/typed-js/, although the goal would be to make it user-oriented rather than developer-oriented. This could easily blow-up into its own unique little creative application, so I'll just note the potential for something like this, but defer it indefinitely. 
