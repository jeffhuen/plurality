defmodule Plurality.ConfigTest do
  use ExUnit.Case

  # Cannot be async because we modify application config
  # which is global state.

  defmodule TestInflection do
    use Plurality.Custom,
      irregulars: [{"regex", "regexen"}],
      uncountables: ["kubernetes"]
  end

  describe "app-wide config delegation" do
    setup do
      # Ensure clean state before and after each test
      Application.delete_env(:plurality, :custom_module)
      on_exit(fn -> Application.delete_env(:plurality, :custom_module) end)
    end

    test "without config, uses default engine" do
      assert Plurality.pluralize("regex") == "regexes"
      assert Plurality.pluralize("leaf") == "leaves"
    end

    test "with config, delegates to custom module" do
      Application.put_env(:plurality, :custom_module, TestInflection)

      assert Plurality.pluralize("regex") == "regexen"
      assert Plurality.pluralize("kubernetes") == "kubernetes"
      assert Plurality.singularize("regexen") == "regex"
      assert Plurality.singular?("kubernetes") == true
      assert Plurality.plural?("kubernetes") == true
    end

    test "custom module falls through to defaults for unknown words" do
      Application.put_env(:plurality, :custom_module, TestInflection)

      assert Plurality.pluralize("leaf") == "leaves"
      assert Plurality.singularize("children") == "child"
      assert Plurality.plural?("leaves") == true
      assert Plurality.singular?("leaf") == true
    end

    test "inflect delegates to custom module" do
      Application.put_env(:plurality, :custom_module, TestInflection)

      assert Plurality.inflect("regex", 1) == "regex"
      assert Plurality.inflect("regex", 2) == "regexen"
    end

    test "config can be removed to restore defaults" do
      Application.put_env(:plurality, :custom_module, TestInflection)
      assert Plurality.pluralize("regex") == "regexen"

      Application.delete_env(:plurality, :custom_module)
      assert Plurality.pluralize("regex") == "regexes"
    end
  end
end
