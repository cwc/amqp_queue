defmodule AMQPQueue.EnqueueHandler do
  @moduledoc "This event handler publishes the event payload to the configured exchange."

  use GenEvent

  def init(state = %{connection_url: url, exchange_name: exchange}) do
    {:ok, conn} = AMQP.Connection.open(url)
    {:ok, chan} = AMQP.Channel.open(conn)

    # Declare the exchange
    :ok = AMQP.Exchange.declare(chan, exchange)

    state = Map.put(state, :chan, chan)
    |> Map.put(:conn, conn)

    {:ok, state}
  end

  def handle_event({payload, routing_key}, state = %{chan: chan, exchange_name: exchange}) do
    :ok = AMQP.Basic.publish(chan, exchange, routing_key, payload)

    {:ok, state}
  end

  def handle_event(payload, state = %{chan: chan, exchange_name: exchange}) do
    key = state[:routing_key] || ""

    :ok = AMQP.Basic.publish(chan, exchange, key, payload)

    {:ok, state}
  end
end
