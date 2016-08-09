#### July 14, 2016

So, [file monitoring](../diffing/FileMonitoring.md) is simply not going to give
me the instantaneous feedback that I need for this app, without muddling with
editor-specific code. But browsers are extremely portable, so I'll be using that
as the main environment.

This unfortunately means that being able to record how someone programs
something won't be naturally supported like it would be if I could do this for
an arbitrary local file. So, I'll defer support for features like this
indefinitely, until my original idea has at least a minimum viable
implementation.

#### July 13, 2016

So, the core feature of this tool is simply recording every single change you
make while writing something (and obviously doing more interesting things with
that data than just storing raw keystrokes). My initial desire for this sprung
out of wanting to not be fake while writing an essay-like thing, as it's so easy
to just curate yourself into some image, like Facebook culture, and there's just
this fundamental falseness to it that I don't want to exist. When I talk to
people, I say things that are dumb, express convictions that I refute 5 seconds
later, have immediate regrets, and other raw, small failures of being a human.
The curated, refined product that text or images can be aren't reflective of
real people, not their in-the-flesh selves.

But I also realize that this could be put to other uses. One thing I thought of
is that it could give people the opportunity to essentially record themselves
while coding, and allow people to play back their session (similarly to how you
can use Elm's time-travelling debugger; I should actually consider using Elm for
this project...). This could both just be a fun little thing to do, to see the
progress of how something is made, and the patterns in which people think, but
also could potentially be an educational experience for people to see how other
people write their code. Khan Academy actually uses something similar to this in
some of the JS programming tutorials, where you get to experience the instructor
typing live, but can rewind or fast-forward.

I'm sure there's other people/projects/apps doing these things in a bunch of
different ways already, but yeah, it's definitely really interesting to think
about how analyzing our writing patterns can illuminate our thought-processes,
and storing a full changeset for everything typed gives a fairly good dataset
for that. The key here is figuring out what the dataset should look like, what
things to record and what levels to abstract on (keypresses, words, lines,
etc..).

So back to the mention of Elm. Reactive web forms (that is, which send the
current form-data to the JS app with every keypress) are definitely a potential
interface for a tool like this, as an alternative to watching files or using the
terminal for input/editing. But I don't want to start with that unless it would
actually be easier (I have hardly done any file-system stuff before, so I'm not
sure about the capabilities yet).

So, before I can elaborate on more features, I first need to do some research
into file-system monitoring.
