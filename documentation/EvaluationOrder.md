When trying to sequence multiple messages together (WrapWordsAndPersist) I ran
into a problem related to functions which require side-effects to evaluate.
Elaborations follow (this is very useful information for building more complex
interactions).


An example illustrating the problem of trying to sequence commands where the
former only updates a model after its side-effect has triggered, and the latter
requires that the model be updated by the former to work properly.
```
{- inside the main update function -}
  EvaluateEarlyThenLate ->
    let
      (model', cmd) = update EarlyWithSideEffect model {- Early won't update the model until the side-effect triggers (get the current time) -}
      (model'', cmd') = update Late model'  {- Late needs to work with the updated model from Early, meaning it needs the model after the side-effect has triggered -}
    in
      model'' ! [cmd, cmd']
```

Here's the history from Slack on this:

montanonic
12:25 AM Elm's evaluation order is a bit unclear to me, namely with what recursively calling the update function within another update clause does.
12:25 I'm stuck in particular with the following (simplified) situation:
debois
12:32 AM @montatonic: other option for onInput (if it bubbles, I forget) is to install a second onInput higher up the DOM.
montanonic
12:34 AM I have two messages, let's say, message Early and message Late, that update the model. Message Late always needs to happen ​after​ message Early, because it depends on the model being ​updated by​ Early. But, here's the kicker: message Early requires fetching the time to properly update the model, so what it actually does is perform a Task with Time.now and, meaning that it finishes evaluating inside of another message, EarlyWithTime.
debois
12:34 AM You can observe the evaluation order using Debug.log. I don't know what it is, but I'd expect f x y evaluates first f (not calling f, but figuring out what function f is), then x, then y, then the call f x y.
montanonic
12:34 AM debois: I've been using Debug.log and that's what got me to realize why my function wasn't working properly: evaluation wasn't happening in the order I thought it would
12:35 So the way I've been writing the example above is as:
debois
12:35 AM What triggers Late?
montanonic
12:35 AM I'll show you in 1 min, as I type a brief example
debois
12:36 AM Ok. (Waiting with bated breath ;)
montanonic
12:37 AM

{- inside the main update function -}
  EvaluateEarlyThenLate ->
    let
      (model', cmd) = update EarlyWithSideEffect model {- Early won't update the model until the side-effect triggers (get the current time) -}
      (model'', cmd') = update Late model'  {- Late needs to work with the updated model from Early, meaning it needs the model after the side-effect has triggered -}
    in
      model'' ! [cmd, cmd']

(edited)
12:37 using ! from http://package.elm-lang.org/packages/elm-lang/core/4.0.3/Platform-Cmd
12:38 But when Late fires, the model hasn't been updated
12:39 because Early doesn't update the model until its Cmd evaluates
12:39 if that makes sense
12:39 since Early needs to fetch the current time
debois
12:40 AM update Early returns model' and cmd. Is it that you need this cmd to run before update Late?
montanonic
12:40 AM yes, I believe that's the exact problem
12:40 and I was just assuming/hoping Cmd.batch would ​just work​, but, it doesn't seem to be the case here
mbaumann
12:40 AM Thats a really good example, btw.
montanonic
12:41 AM ty :slightly_smiling_face: ; tried to simplify the logic as best I could from my project
12:46 The consequence of this is that my Late message always evaluates 1 step later than it ought to, because the model it relies upon is always lagging behind it by one update, given that it receives the same model that EarlyWithSideEffect receives, not the one that it produces, until the next evaluation loop. (edited)
chipf0rk
12:48 AM The thing is that you're collecting a list of commands that aren't executed until you hand them back to the runtime - which is when you actually return model'' ! [cmd, cmd'] at the end.
12:48 update itself is pure, so just calling it recursively can't actually have any side effect, right?
montanonic
12:48 AM yes, it is pure come to think of it
chipf0rk
12:49 AM exactly, so that's why the commands are ​only​ executed when you actually really return
montanonic
12:49 AM recursion can only alter the model and batch commands
12:49 right, so I need a way to sequence events to occur after a command
chipf0rk
12:49 AM Is it possible for you to ask for Time.now with a specific Msg that lets your update know that now's the time to actually do the Late thing?
12:50 that's usually what you do, make one update branch return a Cmd that asks for something and hands back a different Msg, and then a branch that handles that (asynchronously incoming) Msg (edited)
montanonic
12:51 AM hmm, definitely possible, and I'll do that and appreciate the help. But, that's also already how my Early function works, and I was just hoping I wouldn't have to break this new message into two messages to properly fetch the time
12:51 given that Early already encapuslates that logic, that is
chipf0rk
12:52 AM Yeah, I think you do have to, though. You add a new possible Msg value to react when a specific thing that a Cmd fetches arrives
12:52 I'm not so sure I understand, do you mean both your Early and Late steps have to wait for something to arrive from a Cmd?
montanonic
12:55 AM Sorry, I mean that Early does the asynchronous message thing that you were saying, and I wish there was a way to say: "wait for Early to evaluate, and ​then​ use the results from that in the Late message"
12:55 without having to say EvaluateEarlyThenLate -> ......       EvaluateEarlyThenLateWithTime time -> .....
12:56 which again, I somehow thought Cmd.batch knew to do? But it's clearer to me now why that doesn't work, and what's actually happening
12:57 so this has been very informative :slightly_smiling_face:
chipf0rk
12:59 AM if you can describe something in Tasks, you can use andThen
12:59 I'm not sure if that applies :smile:
montanonic
12:59 AM I'm not sure either, but will keep in mind :slightly_smiling_face:
1:00 I'm also already andThening with http://package.elm-lang.org/packages/ccapndave/elm-update-extra/2.1.0/Update-Extra :smile:
1:00 (it just turns into the same code above though)
1:04 So, I guess the rule of thumb would be: if you're trying to chain multiple messages together, this will work perfectly if they use no commands. If you need to chain messages which use commands, you'll need to split yourself into multiple messages, fire the commands, collect the results, and then sequence the model using completely pure code.
1:04 Short version is: are your messages pure or asynchronous? batch them and it will work fine (edited)
1:05 are (at least some) impure and sequential? separate the impure parts into another message(s), and send the results of that to a final message which will sequence everything together (edited)
