Code.require_file "test_helper.exs", __DIR__

defmodule Poxa.EventHandlerTest do
  use ExUnit.Case
  alias Poxa.PusherEvent
  alias Poxa.Authentication
  import Poxa.EventHandler

  setup do
    :meck.new PusherEvent
    :meck.new Authentication
    :meck.new :jsx
    :meck.new :cowboy_req
  end

  teardown do
    :meck.unload PusherEvent
    :meck.unload Authentication
    :meck.unload :jsx
    :meck.unload :cowboy_req
  end

  test "init with a valid json" do
    :meck.expect(:cowboy_req, :body, 1,
                {:ok, :body, :req1})
    :meck.expect(:jsx, :is_json, 1, true)

    assert init(:transport, :req, :opts) == {:ok, :req1, :body}

    assert :meck.validate :cowboy_req
    assert :meck.validate :jsx
  end

  test "init with a invalid json" do
    :meck.expect(:cowboy_req, :body, 1,
                {:ok, :body, :req1})
    :meck.expect(:jsx, :is_json, 1, false)
    :meck.expect(:cowboy_req, :reply, 4,
                {:ok, :req2})

    assert init(:transport, :req, :opts) == {:shutdown, :req2, nil}

    assert :meck.validate :cowboy_req
    assert :meck.validate :jsx
  end

  test "single channel event" do
    :meck.expect(Authentication, :check, 3, :ok)
    :meck.expect(:cowboy_req, :qs_vals, 1, {:qsvals, :req2})
    :meck.expect(:cowboy_req, :path, 1, {:path, :req3})
    :meck.expect(:jsx, :decode, 1,
                [{"channel", "channel_name"},
                 {"name", "event_etc"} ])
    :meck.expect(:cowboy_req, :reply, 4, {:ok, :req4})
    :meck.expect(PusherEvent, :parse_channels, 1,
                {[{"name", "event_etc"}], :channels, nil})
    :meck.expect(PusherEvent, :send_message_to_channels, 3, :ok)

    assert handle(:req, :state) == {:ok, :req4, nil}

    assert :meck.validate PusherEvent
    assert :meck.validate Authentication
    assert :meck.validate :cowboy_req
    assert :meck.validate :jsx
  end

  test "single channel event excluding socket_id" do
    :meck.expect(Authentication, :check, 3, :ok)
    :meck.expect(:cowboy_req, :body, 1,
                {:ok, :body, :req1})
    :meck.expect(:cowboy_req, :qs_vals, 1, {:qsvals, :req2})
    :meck.expect(:cowboy_req, :path, 1, {:path, :req3})
    :meck.expect(:jsx, :decode, 1, :decoded_json)
    :meck.expect(:cowboy_req, :reply, 4, {:ok, :req4})
    :meck.expect(PusherEvent, :parse_channels, 1,
                {[{"name", "event_etc"}], :channels, :exclude})
    :meck.expect(PusherEvent, :send_message_to_channels, 3, :ok)
    :meck.expect(:cowboy_req, :reply, 4, {:ok, :req4})

    assert handle(:req, :state) == {:ok, :req4, nil}

    assert :meck.validate PusherEvent
    assert :meck.validate Authentication
    assert :meck.validate :cowboy_req
    assert :meck.validate :jsx
  end

  test "multiple channel event" do
    :meck.expect(Authentication, :check, 3, :ok)
    :meck.expect(:cowboy_req, :body, 1,
                {:ok, :body, :req1})
    :meck.expect(:cowboy_req, :qs_vals, 1, {:qsvals, :req2})
    :meck.expect(:cowboy_req, :path, 1, {:path, :req3})
    :meck.expect(:jsx, :decode, 1, :decoded_json)
    :meck.expect(:cowboy_req, :reply, 4, {:ok, :req4})
    :meck.expect(PusherEvent, :parse_channels, 1,
                {[{"name", "event_etc"}], :channels, nil})
    :meck.expect(PusherEvent, :send_message_to_channels, 3, :ok)
    :meck.expect(:cowboy_req, :reply, 4, {:ok, :req4})

    assert handle(:req, :state) == {:ok, :req4, nil}

    assert :meck.validate PusherEvent
    assert :meck.validate Authentication
    assert :meck.validate :cowboy_req
    assert :meck.validate :jsx
  end

  test "undefined channel event" do
    :meck.expect(Authentication, :check, 3, :ok)
    :meck.expect(:cowboy_req, :body, 1,
                {:ok, :body, :req1})
    :meck.expect(:cowboy_req, :qs_vals, 1, {:qsvals, :req2})
    :meck.expect(:cowboy_req, :path, 1, {:path, :req3})
    :meck.expect(:jsx, :decode, 1, :decoded_json)
    :meck.expect(:cowboy_req, :reply, 4, {:ok, :req4})
    :meck.expect(PusherEvent, :parse_channels, 1,
                {[{"name", "event_etc"}], nil, nil})

    assert handle(:req, :state) == {:ok, :req3, nil}

    assert :meck.validate Authentication
    assert :meck.validate :cowboy_req
    assert :meck.validate :jsx
  end

  test "failing authentication" do
    :meck.expect(Authentication, :check, 3, :error)
    :meck.expect(:cowboy_req, :body, 1,
                {:ok, :body, :req1})
    :meck.expect(:cowboy_req, :qs_vals, 1, {:qsvals, :req2})
    :meck.expect(:cowboy_req, :path, 1, {:path, :req3})
    :meck.expect(:jsx, :decode, 1, :decoded_json)

    assert handle(:req, :state) == {:ok, :req3, nil}

    assert :meck.validate Authentication
    assert :meck.validate :cowboy_req
    assert :meck.validate :jsx
  end
end
