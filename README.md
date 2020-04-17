# README #

### TODO ###
- [ ] conditions
- [x] organise code
- [ ] JWT support
- [ ] more examples
- [ ] more doc && README
- [ ] protocol connection

## Usage ##

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


Then, check `examples.lisp`
