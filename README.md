# CPEE Replayer

To install the replayer service go to the commandline

```bash
 gem install cpee-replayer
 cpee-replayer replayer
 cd replayer
 ./task start
```

The service is running under port 9300. If this port has to be changed (or the
host, or local-only access, ...), create a file log.conf and add one
or many of the following yaml keys:

```yaml
 :port: 9250
 :host: cpee.org
 :bind: 127.0.0.1
```

To connect the cpee to the replayer, one of two things can be done: (1) add a handler to
a testset/template:

```xml
  <handlers>
    <handler url="http://localhost:9300/">
      <events topic="description">change</events>
      <events topic="state">change</events>
    </handler>
  </handlers>
```

(2) add a default handler to the cpee by adding

```ruby
Riddl::Server.new(CPEE::SERVER, options) do
  ...
  @riddl_opts[:notifications_init] = File.join(__dir__,'resources','notifications')
  ...
  use CPEE::implementation(@riddl_opts)
end.loop!
```

to the server (or alternatively to a cpee.conf with :notification_init
beeing a top-level yaml key). Then add a subscription file to
notifications/logging/subscription.xml

```xml
<subscription xmlns="http://riddl.org/ns/common-patterns/notifications-producer/2.0" url="http://localhost:9300/">
  <topic id="description">
    <event>change</event>
  </topic>
  <topic id="state">
    <event>change</event>
  </topic>
</subscription>
```

Furthermore the following addition has to be made to every instance that acts as a
replayer base instance:

* Add attribute ''replayer'' that points to http://localhost:9300/ or any url with a replayer
* Add attribute ''replayer_target'' which points to a xes-yaml file (generated with a least cpee-logging-xes-yaml 1.0.3)
