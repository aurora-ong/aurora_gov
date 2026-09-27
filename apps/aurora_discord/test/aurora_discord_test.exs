defmodule AuroraDiscordTest do
  use ExUnit.Case
  doctest AuroraDiscord

  test "greets the world" do
    assert AuroraDiscord.hello() == :world
  end
end
