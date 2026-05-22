defmodule Plurality.ConfigTest do
  use ExUnit.Case

  defmodule TestInflection do
    use Plurality.Custom,
      irregulars: [{"regex", "regexen"}],
      uncountables: ["kubernetes"]
  end

  describe "explicit custom modules" do
    setup do
      Application.delete_env(:plurality, :custom_module)
      on_exit(fn -> Application.delete_env(:plurality, :custom_module) end)
    end

    test "Plurality uses default engine directly" do
      assert Plurality.pluralize("regex") == "regexes"
      assert Plurality.pluralize("leaf") == "leaves"
    end

    test "application config does not affect Plurality calls" do
      Application.put_env(:plurality, :custom_module, TestInflection)

      assert Plurality.pluralize("regex") == "regexes"
      assert Plurality.pluralize("kubernetes") == "kuberneteses"
      assert Plurality.singularize("regexen") == "regexen"
    end

    test "custom module is called directly" do
      assert TestInflection.pluralize("regex") == "regexen"
      assert TestInflection.pluralize("kubernetes") == "kubernetes"
      assert TestInflection.singularize("regexen") == "regex"
      assert TestInflection.plural?("kubernetes") == true
      assert TestInflection.singular?("kubernetes") == true
    end

    test "custom module falls through to defaults for unknown words" do
      assert TestInflection.pluralize("leaf") == "leaves"
      assert TestInflection.singularize("children") == "child"
      assert TestInflection.plural?("leaves") == true
      assert TestInflection.singular?("leaf") == true
    end

    test "custom inflect uses the custom module" do
      assert TestInflection.inflect("regex", 1) == "regex"
      assert TestInflection.inflect("regex", 2) == "regexen"
    end
  end
end
