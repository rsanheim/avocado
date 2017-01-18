
### Development

To run avocado locally:

  ruby -Ilib bin/avocado status


### Notifications

Use `say` or whatever tool your platform has for notifications:

```
  avocado watch && say "avocado complete" || (say "avocado aborted")
```
