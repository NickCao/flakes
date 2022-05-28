TL;DR: [pam-oauth2](https://github.com/SCP-2000/pam-oauth2)

#### which oauth2 flow to use
OAuth2, rather than an opinionated authorization protocol, is a framework in which numerous flows (or grants) are defined: code flow, implicit flow, pkce flow and more. For our particular use case, there are two points to consider. First, no reliance on third party endpoint, the authorization flow should be able to be conducted between only sshd and github. Second, untrusted execution environment, as the pam module would be deployed in the wild, there should be no client secret included in the flow.

[OAuth 2.0 Device Authorization Grant](https://tools.ietf.org/html/rfc8628) is our final choice. Unlike the other common flows, it does not require the use of a callback endpoint, which fulfills the first consideration. And it uses only the client id, and a locally generated device code for exchanging the access token, which satisfies the second point.

For a quick glimpse into the flow, here is a visualization, copied from the linked rfc.
```
      +----------+                                +----------------+
      |          |>---(A)-- Client Identifier --->|                |
      |          |                                |                |
      |          |<---(B)-- Device Code,      ---<|                |
      |          |          User Code,            |                |
      |  Device  |          & Verification URI    |                |
      |  Client  |                                |                |
      |          |  [polling]                     |                |
      |          |>---(E)-- Device Code       --->|                |
      |          |          & Client Identifier   |                |
      |          |                                |  Authorization |
      |          |<---(F)-- Access Token      ---<|     Server     |
      +----------+   (& Optional Refresh Token)   |                |
            v                                     |                |
            :                                     |                |
           (C) User Code & Verification URI       |                |
            :                                     |                |
            v                                     |                |
      +----------+                                |                |
      | End User |                                |                |
      |    at    |<---(D)-- End user reviews  --->|                |
      |  Browser |          authorization request |                |
      +----------+                                +----------------+
```
In our case, device client is sshd, or more specifically, the pam module, and authorization server is github. As device flow was intended for clients that have limited input capabilities, it utilizes long polling to wait for the completion of authorization, which does not hold in sshd. Thus we implemented a simplified version of device flow, effectively cutting out the polling, and replaced it with user confirmation.
```
      +----------+                                +----------------+
      |          |>---(A)-- Client Identifier --->|                |
      |          |                                |                |
      |          |<---(B)-- Device Code,      ---<|                |
      |          |          User Code,            |                |
      |  Device  |          & Verification URI    |                |
      |  Client  |                                |                |
      |          |                                |                |
      |          |>---(F)-- Device Code       --->|                |
      |          |          & Client Identifier   |                |
      |          |                                |  Authorization |
      |          |<---(G)-- Access Token      ---<|     Server     |
      +----------+                                |                |
       ^    v                                     |                |
       :    :                                     |                |
       :   (C) User Code & Verification URI       |                |
      (E)   :  User Confirmation                  |                |
       ^    v                                     |                |
      +----------+                                |                |
      | End User |                                |                |
      |    at    |<---(D)-- End user reviews  --->|                |
      |  Browser |          authorization request |                |
      +----------+                                +----------------+
```
A side effect of this simplified flow is that it reduces the impact of dos attack on the pam module.

#### which programming language to use
At first, go was choosen to implement the pam module, as I'm more familiar with go, and the interoperability between c and go is somehow mature. During the first few iterations, everything were going smoothly, both pamtester and sudo played well. When it's time to dump it right into sshd, things started to get horriblly wrong: not even a single word was sent back from sshd to prompt user for authorization. Jumped down the rabbit hole, caught a few bugs from the ancient years (that is sshd buffering `PAM_TEXT_INFO` until the end of authentication), still, sshd is like dumb or what. Several commit messages with f-word sneaked in, then the project was effectively abandoned. Days later, I decided to pick it back up, and give rust a try, magically, all the bugs were ironed out, like if they were never there, and apart for the struggle fighting with borrow checker to create self-referential structs, the coding experience is euqally smooth.

#### what does it look like
```
$ ssh user@foo.example.com
please go to https://github.com/login/device and input 88C3-9CF9 then press enter here
# a page to enter the code, then the same authorization page
# as you would see for other oauth2 applications
<enter>
[user@foo ~]$
```

#### after words
It works, right? however the user experience has some rough edges, who ever wanna copy and paste the code? Not with totp, nor with a pam module. In fact, in the rfc, there exists a optional response field called `verification_uri_complete`, and if implemented, contains the user code so that the user can go directly to the given uri, and just press authorize. For reasons we don't know, github does not implement this, and we still have to copy and pasta.
