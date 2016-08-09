module Diffing exposing (..)

import Time exposing (Time)
import String
import Array exposing (Array)


{- The diffing algorithm will be given the following data:

   LineIndex Content Time

   It will also have access to the DiffChain data, of course, which means that in
   the current implementation it will have access to the data from the previous
   line (or I'm not sure if it actually does with the migration from textarea to
   input, so I need to make sure it has the previously line to diff with.

   Unless it doesn't need the previous line? If diffing is actually just
   instructions on how to turn the previous line into the current one; yeah, no,
   we will need the full contents of the previous line.

   AHH!! I figured out another (potential) efficiency solution. We listen for
   mouse-down events! if the user hasn't clicked since last typing, then we can
   actually just use the user's character keypress information to do the diff,
   which will mean we have to handle the alphanumerical keys (and this may get
   *way* more complicated in order to handle unicode). Anyways, the point is
   that if there's no mouse down event, then the user hasn't selected text,
   which means they can't overwrite a block of text, which means that, absent
   copy-pasting, we know that they will have only inserted a single character.
   But, again, with unicode support, this might be a different story. Example: é
   took 3 key-presses to write on my pc. That should clearly only count as one
   character though, so we'd need to make sure that listening for key-presses
   functioned properly in the presence of things like that. Oh yeah, finally,
   mouse down with no mouse up means text possibly selected. Mouse-up with no
   single-click after means text possibly selected. Mouse click means no text
   could have been selected.


   ctrl-V events may be another story though... I'll worry about that in due time.



   The next reforumulation about how diffing should work is that I should think
   about it as if it a list of instructions describing how to transform some
   data type. I think this idea was already present, but I want to emphasize how
   core this is.

-}
{- Scratch area to figure out what "update instructions" should look like.

   So, if a line was modified by adding content to the end of the line, we can
   simply simply add the keypress to the diffchain with the "Append"
   instruction, and the line it exists at. This method depends on ideas
   expressed in the optimization discussion above. I will move this to more
   fleshed out documentation pages as the ideas coalesce. Here's what an element
   in this chain might look like for this:

   { action: Append, content: 's', lineIndex: 4 }

   This chain element reflects an instruction to append the 's' character to the
   end of the String on line 4. This is an O(n) operation, so I might want to
   rethink line-content as an explicit Array of characters rather than a string.
   But I may still have to transform it into a List at the end for every update,
   which is again O(n) anyways... so yeah. This could be faster if I were to
   batch updates together, but the problem with that is that I *want* the
   animations to update character-by-character. So I'm going to try for that,
   and only do otherwise if it's too slow.

   Characters added at the beginning of a line would be labeled as Prepend
   actions.

   Here's the thing though: while recording content, it makes sense to index
   things by lines, so that I know where the user added the content. But while
   interpreting the diffchain to reanimate what a user typed, I don't at all
   need to use the same format that the user typed things in, that is, it
   doesn't necessarily need to be line-aware. I really can't tell what a good
   alternative model may look like, but the point is that I may not need to
   adhere strictly to lines. Then again, if I don't do that, then the animation
   faces the same type of problem the recording does: it has to traverse the
   entire data structure somehow. Even if I break operations down to modifying
   an array of string slices (so that I can pinpoint updates with minimal
   traversals), how to then *render* this array of strings will likely involve
   doing a full traversal to concatenate the strings, bringing everything back
   to square one.

   So I actually think that the diffchain should be line-aware, as rendering
   updates could only be efficient if that were the case. Of course, word
   overflow calculations may negate most of the performance benefits of that
   (I'll need to manually tell each input field how to change itself in response
   to the user pushing words past the end of the line they're writing on (this
   is discussed in more detail in the top-level brainstorm doc on `Diffing`).


   Since prepends on Strings will essentially always be much faster than appends
   (especially as the string gets closer to the character limit), I'd like to
   consider ways of amortizing the costs somehow, perhaps by offloading certain
   computations on the prepend action. For example, if I can do some predictive
   look-aheads on the diffchain and calculate when a word-wrap or the like would
   need to happen (consult `brainstorm/Diffing.md` in docs), this cost could be
   expended on the prepend actions. That said, I could also preprocess the
   diffchain to figure out when all word-wraps would need to happen for a given
   character limit, which then makes me realize: I'll already have to calculate
   these things during the reading phase, so this information should already be
   passed to the diffchain. I'll have to think of other possible amortization
   strategies for prepends; word-wrapping is right now, seemingly, the most
   expensive computation.

   One thing that may make it easier to compute word-wraps is to store data
   (perhaps at the same time it's stored as string blobs) as a data structure
   that consists of an array of words along with the current character count.
   Then word wrap updates could be performed by successively chain-popping off
   the elements that would need to be removed at the end of each succesive line,
   storing the elements to be added at the beginning of each line in a buffer
   (Arrays don't support fast prepends), converting each line back to a list of
   words, and then List prepending the elements in the buffer to their
   respective lines. But now I'd need to split all the strings again by words,
   store them back as Arrays, and all that jazz, in preparation for the next
   wrap. Welcome back to expensive. This immediately makes everything O(n)
   again, where n is the number of lines after the current one.

   So yeah, I'll say it again for clarity: how to handle word wrapping is an
   unsolved problem right now.

-}
{-

   It is critical to recognize that diffing as I'm currently talking about it is
   actually slower than using a List containing all the changes to playback the
   animation. What the diffing is actually doing is compressing the data, and
   making it easier cheaper to store/transmit. It would literally be faster
   though to store all the changes raw, like I was doing before (except maybe
   doing a diff on the time values), except for this time there's the benefit of
   many changes only being limit to a single line, cutting things down to
   constant-time as long as word wrapping isn't happening (but, unfortunately,
   word wrapping will probably be happening a lot).

   As such, what I really ought to implement right now is word wrapping, and
   start recording per-line histories, at the cost of ~80 characters an update :)
   (ouch, still expensive, I know; that's the cost of total text-persistence
   though).

-}


{-| This is the preprocessed data:

Raw = ( LineIndex, Content, Time )
-}
type alias Raw =
    ( Int, String, MilliSeconds )


type alias Milliseconds =
    Int


{-| This is a chunk of data along the diff chain. The full sequence of Nodes
produces the full information required to animate an entire text, along with
calculating the final text result at the end, although to save on performance it
will probably be best to store the final Node as its own unique data type,
storing the full final text.

The `textDiff` stores only the values that changed between a modification. In
most cases, this will just be a single value, but sometimes multiple values will
be deleted and/or added at once (copy-pastes), yet are still encapsulated as a
single modification.
-}
type alias Node =
    { timeDiff : Milliseconds
    , textDiff : IndexedDiff
    }


{-| We need to keep track of the previous entry before diffing with the next
entry, as the only way to diff is to compare the current and previous Strings.
So, we'll store the entry at the Head of the diff chain.
-}
type alias Head =
    { node : Node
    , entry : Raw
    }


type alias DiffChain =
    { head : Head
    , rest : List (Node)
    }


type alias Index =
    Int


type Action
    = Added
    | Removed


{-| Changes might be a single character addition, or a chunk of text. It may
just be better to always default to a String, but I'll figure that out later.
-}
type StringOrChar
    = S String
    | C Char


{-| -}
type alias IndexedDiff =
    List ( Action, Index, Char )


{-| The magic. Currently unimplemented, as I feel like this will be quite a bit
easier to implement in Go (despite 9 months of functional programming, sometimes
loops are just easier to write and understand.)

diff : Raw -> Raw -> Node
diff old new =
    let
        {- Whether we iterate over the larger or smaller value doesn't matter,
        but knowing which one is larger/smaller does (I think???). -}
        smaller =
            case compare (String.length old) (String.length new) of
                LT -> old
                EQ -> old
                GT -> new
        reducer : Char -> a -> a
        reducer char (diffAcc, string) =
            case uncons string of
                Just (otherChar, rest) ->
                    if Just char == otherChar then
                        (diffAcc, rest)
                    else
                        (
                    {- here's the problem, I can't know from this information
                    if the char was added or removed; I'll need to do some
                    forward peeking or backtracking, or do multiple passes, or
                    something like this to know for sure.

                    going to actually try writing this in Go now -}
    String.foldr

-}
