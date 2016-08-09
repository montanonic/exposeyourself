So, what if instead of storing copies of lines, I just rendered a textarea, but
kept track of the caret position at all times. Using that position information,
I would listen for keypresses, and update a multidimensional array of which
the first layer represents the position in the text, and the second layer the
history of all characters used in that position.

Now, the difficulties that arise from this model involve properly recognizing
multi-character inserts, but that can be accomplished through tracking the
`selectionStart` *and* `selectionEnd` fields at the same time, which will tell
us which characters changed. Furthermore, copy-pastes can be recognized properly
by seeing that the caret-position moved more than one position in an update!

Furthermore, if specialized characters require multiple keypresses, we can avoid
storing those (incorrectly), by only storing a character once we see that the
caret has moved.

Wow, this seems like a much better design all around. I'll give a shot
implementing it soon.
