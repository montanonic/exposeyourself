## `onInput` triggers oddly when two keys are pressed at essentially same time

Here's the console debug log for what happens when two key presses happen at the
same time ('s' and 'a'), and then with them being pressed very quickly in
sequence.

```
position: 2 main.js:901:3
char as string: "a" main.js:901:3
(index, char): (1,'a') main.js:901:3
char as string: "a" main.js:901:3
(index, char): (1,'a') main.js:901:3
position: 3 main.js:901:3
char as string: "s" main.js:901:3
(index, char): (2,'s') main.js:901:3
position: 4 main.js:901:3
char as string: "a" main.js:901:3
(index, char): (3,'a') main.js:901:3
```

And this is the the history:

```
index: `0` : []
index: `1` : [('a',1470086547179),('a',1470086547179)]
index: `2` : [('s',1470086552923)]
index: `3` : [('a',1470086552947)]
```

And this is what's in the input field:

`sasa`

Clearly pressing keys close enough together where they are registered as a
single input event are incorrect. But the only solution that jumps out at me for
that right now is to replace the `onInput` event with a keypress event that only
triggers for keys that are visibly rendered as characters. And even still I'm
not sure that this would work.
