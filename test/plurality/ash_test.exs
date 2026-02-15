if Code.ensure_loaded?(Ash.Resource.Change) do
  defmodule Plurality.AshTest do
    @moduledoc """
    Tests for Ash integration modules: Changes, Validations, and Calculations.
    These tests only run when Ash is available as a dependency.
    """
    use ExUnit.Case

    alias Plurality.Ash.Calculations
    alias Plurality.Ash.Changes
    alias Plurality.Ash.Validations

    # ── init/1 tests ──────────────────────────────────────────────

    describe "Changes.Pluralize.init/1" do
      test "accepts valid opts" do
        assert {:ok, _} =
                 Changes.Pluralize.init(attribute: :table_name, from: :name)
      end

      test "rejects missing attribute" do
        assert {:error, _} = Changes.Pluralize.init(from: :name)
      end

      test "rejects missing from" do
        assert {:error, _} = Changes.Pluralize.init(attribute: :table_name)
      end
    end

    describe "Changes.Singularize.init/1" do
      test "accepts valid opts" do
        assert {:ok, _} =
                 Changes.Singularize.init(attribute: :resource_name, from: :label)
      end

      test "rejects missing attribute" do
        assert {:error, _} = Changes.Singularize.init(from: :label)
      end

      test "rejects missing from" do
        assert {:error, _} = Changes.Singularize.init(attribute: :resource_name)
      end
    end

    describe "Validations.PluralForm.init/1" do
      test "accepts valid opts" do
        assert {:ok, _} = Validations.PluralForm.init(attribute: :table_name)
      end

      test "rejects missing attribute" do
        assert {:error, _} = Validations.PluralForm.init([])
      end
    end

    describe "Validations.SingularForm.init/1" do
      test "accepts valid opts" do
        assert {:ok, _} = Validations.SingularForm.init(attribute: :resource_name)
      end

      test "rejects missing attribute" do
        assert {:error, _} = Validations.SingularForm.init([])
      end
    end

    describe "Calculations.Pluralize.init/1" do
      test "accepts valid opts" do
        assert {:ok, _} = Calculations.Pluralize.init(attribute: :name)
      end

      test "rejects missing attribute" do
        assert {:error, _} = Calculations.Pluralize.init([])
      end
    end

    describe "Calculations.Singularize.init/1" do
      test "accepts valid opts" do
        assert {:ok, _} = Calculations.Singularize.init(attribute: :name)
      end

      test "rejects missing attribute" do
        assert {:error, _} = Calculations.Singularize.init([])
      end
    end

    # ── Calculation.load/3 tests ──────────────────────────────────

    describe "Calculations.Pluralize.load/3" do
      test "returns the source attribute" do
        assert Calculations.Pluralize.load(nil, [attribute: :name], nil) == [:name]
      end
    end

    describe "Calculations.Singularize.load/3" do
      test "returns the source attribute" do
        assert Calculations.Singularize.load(nil, [attribute: :title], nil) ==
                 [:title]
      end
    end

    # ── Calculation.calculate/3 tests ─────────────────────────────

    describe "Calculations.Pluralize.calculate/3" do
      test "pluralizes attribute values" do
        records = [%{name: "leaf"}, %{name: "child"}, %{name: "sheep"}]
        opts = [attribute: :name]

        assert Calculations.Pluralize.calculate(records, opts, nil) == [
                 "leaves",
                 "children",
                 "sheep"
               ]
      end

      test "handles nil values" do
        records = [%{name: nil}, %{name: "cat"}]
        opts = [attribute: :name]

        assert Calculations.Pluralize.calculate(records, opts, nil) == [nil, "cats"]
      end
    end

    describe "Calculations.Singularize.calculate/3" do
      test "singularizes attribute values" do
        records = [%{name: "leaves"}, %{name: "children"}, %{name: "sheep"}]
        opts = [attribute: :name]

        assert Calculations.Singularize.calculate(records, opts, nil) == [
                 "leaf",
                 "child",
                 "sheep"
               ]
      end

      test "handles nil values" do
        records = [%{name: nil}, %{name: "cats"}]
        opts = [attribute: :name]

        assert Calculations.Singularize.calculate(records, opts, nil) == [
                 nil,
                 "cat"
               ]
      end
    end
  end
end
