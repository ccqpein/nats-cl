# README #

## Install ##

manually compile and use this repo

```lisp
(push "/path/to/nats-cl/" asdf:*central-registry*)

(asdf:compile-system :nats-cl)

(asdf:load-system :nats-cl)
```

OR, import by quicklisp, make sure you have installed it first:

```lisp
;;; put this repo in ql:*local-project-directories*
(ql:quickload "nats-cl")
```

## Usage ##

[Here](https://docs.nats.io/nats-protocol/nats-protocol#protocol-conventions) is NATs' protocol details. 

`examples.lisp` includes how to use this client lib.

After connection be made, NATs server will send a `INFO` message and a `PING` message to client. So, in examples: 

```lisp
(let ((socket (connect-nats-server "127.0.0.1")) 
      info)
  (multiple-value-setq (sokt info) (post-connection sokt)))
```

`post-connection` always the first step after connect to servers.


### TODO ###
- [x] conditions
- [x] organise code
- [ ] JWT support
- [ ] Leaf nodes
- [x] more examples
- [ ] more doc && README
- [ ] protocol connection
