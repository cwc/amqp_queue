# AMQPQueue

A simple toolkit for working with AMQP queues.

## Installation

  1. Add amqp_queue to your list of dependencies in `mix.exs`:

        def deps do
          [
              {:amqp_queue, github: "cwc/amqp_queue"}
          ]
        end

  2. Ensure amqp_queue is started before your application:

        def application do
          [applications: [
              :amqp_queue
          ]]
        end

## Usage


### Configure queue workers 

The application will supervise workers specified in your application's `config.exs`:

        config :amqp_queue, :workers, [
            [
                "amqp://localhost",             # Connection URL
                "my_exchange",                  # Exchange name
                "my_work_queue",                # Queue name (empty to generate one, for unshared queues)
                [ {PayloadEventHandler, []} ],  # List of payload event handlers (GenEvent spec) in the form `{HandlerModule, args}`
                [prefetch_count: 10]            # Additional options
            ],

            ... # Add as many consumers as you need
        ]

### Send data to an exchange

A simple `GenEvent`-style event handler is provided for pushing data to an exchange:

    GenEvent.add_handler(
        mgr_pid,
        AMQPQueue.EnqueueHandler,
        %{
            connection_url: "amqp://localhost",
            exchange_name: "my_exchange",
            routing_key: "key.default"              # Optional
        }
    )

    # Use the default routing key
    GenEvent.notify(mgr_pid, "payload")

    # Specify a routing key
    GenEvent.notify(mgr_pid, {"payload", "key.specific"})
