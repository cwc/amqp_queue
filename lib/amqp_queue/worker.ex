defmodule AMQPQueue.Worker do
  @moduledoc "This worker delivers queue payloads to the configured event handlers."

  use ExActor.Tolerant
  require Logger

  defstart start_link(connection_url, exchange, queue_name \\ "", handlers, opts \\ [prefetch_count: 10]) do
    unless connection_url, do: raise "You must provide an AMQP connection URL."
    unless exchange, do: raise "You must provide an exchange name."

    {:ok, conn} = AMQP.Connection.open(connection_url)
    {:ok, chan} = AMQP.Channel.open(conn)

    if Keyword.has_key?(opts, :prefetch_count) do
      AMQP.Basic.qos(chan, prefetch_count: opts[:prefetch_count])
    end

    # Declare and bind exchange and queue
    :ok = AMQP.Exchange.declare chan, exchange
    {:ok, %{queue: queue}} = AMQP.Queue.declare chan, queue_name
    :ok = AMQP.Queue.bind chan, queue, exchange

    {:ok, tag} = AMQP.Basic.consume(chan, queue)

    Logger.info("#{inspect self} is now consuming #{queue} on #{connection_url}.")

    {:ok, %{conn: conn, chan: chan, consumer_tag: tag, exchange: exchange, queue: queue, handlers: handlers}}
  end

  defhandleinfo {:basic_deliver, payload, %{delivery_tag: tag}}, state: state do
    for {h, args} <- state.handlers do
      h.handle_event(payload, args)
    end

    :ok = AMQP.Basic.ack(state.chan, tag)

    noreply
  end

  defhandleinfo _, do: noreply
end
