defmodule Plurality.BusinessTest do
  @moduledoc """
  Business/technical domain tests — terms across 8 domains covering
  e-commerce, finance, legal, software, data, HR, irregulars, and Latin/Greek.
  """
  use ExUnit.Case

  # ── E-commerce ──────────────────────────────────────────────────

  describe "e-commerce terms" do
    test "pluralize" do
      assert Plurality.pluralize("invoice") == "invoices"
      assert Plurality.pluralize("refund") == "refunds"
      assert Plurality.pluralize("warranty") == "warranties"
      assert Plurality.pluralize("shipment") == "shipments"
      assert Plurality.pluralize("discount") == "discounts"
      assert Plurality.pluralize("coupon") == "coupons"
      assert Plurality.pluralize("receipt") == "receipts"
      assert Plurality.pluralize("catalog") == "catalogs"
      assert Plurality.pluralize("inventory") == "inventories"
      assert Plurality.pluralize("merchandise") == "merchandise"
      assert Plurality.pluralize("cargo") == "cargoes"
      assert Plurality.pluralize("freight") == "freight"
    end
  end

  # ── Finance ─────────────────────────────────────────────────────

  describe "finance terms" do
    test "pluralize" do
      assert Plurality.pluralize("portfolio") == "portfolios"
      assert Plurality.pluralize("dividend") == "dividends"
      assert Plurality.pluralize("equity") == "equities"
      assert Plurality.pluralize("liability") == "liabilities"
      assert Plurality.pluralize("premium") == "premiums"
      assert Plurality.pluralize("index") == "indices"
      assert Plurality.pluralize("tax") == "taxes"
      assert Plurality.pluralize("tariff") == "tariffs"
      assert Plurality.pluralize("surplus") == "surpluses"
      assert Plurality.pluralize("deficit") == "deficits"
    end
  end

  # ── Legal ───────────────────────────────────────────────────────

  describe "legal terms" do
    test "pluralize" do
      assert Plurality.pluralize("attorney") == "attorneys"
      assert Plurality.pluralize("plaintiff") == "plaintiffs"
      assert Plurality.pluralize("testimony") == "testimonies"
      assert Plurality.pluralize("jury") == "juries"
      assert Plurality.pluralize("statute") == "statutes"
      assert Plurality.pluralize("amendment") == "amendments"
      assert Plurality.pluralize("contract") == "contracts"
      assert Plurality.pluralize("clause") == "clauses"
      assert Plurality.pluralize("verdict") == "verdicts"
    end
  end

  # ── Software / DevOps ──────────────────────────────────────────

  describe "software/devops terms" do
    test "pluralize" do
      assert Plurality.pluralize("schema") == "schemas"
      assert Plurality.pluralize("middleware") == "middleware"
      assert Plurality.pluralize("software") == "software"
      assert Plurality.pluralize("firmware") == "firmware"
      assert Plurality.pluralize("status") == "statuses"
      assert Plurality.pluralize("access") == "accesses"
      assert Plurality.pluralize("process") == "processes"
      assert Plurality.pluralize("address") == "addresses"
      assert Plurality.pluralize("interface") == "interfaces"
      assert Plurality.pluralize("database") == "databases"
      assert Plurality.pluralize("repository") == "repositories"
      assert Plurality.pluralize("registry") == "registries"
      assert Plurality.pluralize("proxy") == "proxies"
      assert Plurality.pluralize("query") == "queries"
      assert Plurality.pluralize("throughput") == "throughput"
    end

    test "singularize" do
      assert Plurality.singularize("schemas") == "schema"
      assert Plurality.singularize("statuses") == "status"
      assert Plurality.singularize("processes") == "process"
      assert Plurality.singularize("addresses") == "address"
      assert Plurality.singularize("interfaces") == "interface"
      assert Plurality.singularize("databases") == "database"
      assert Plurality.singularize("repositories") == "repository"
      assert Plurality.singularize("queries") == "query"
    end
  end

  # ── Data / Analytics ───────────────────────────────────────────

  describe "data/analytics terms" do
    test "pluralize" do
      assert Plurality.pluralize("analysis") == "analyses"
      assert Plurality.pluralize("hypothesis") == "hypotheses"
      assert Plurality.pluralize("thesis") == "theses"
      assert Plurality.pluralize("criterion") == "criteria"
      assert Plurality.pluralize("datum") == "data"
      assert Plurality.pluralize("matrix") == "matrices"
      assert Plurality.pluralize("vertex") == "vertices"
      assert Plurality.pluralize("formula") == "formulas"
      assert Plurality.pluralize("appendix") == "appendices"
    end
  end

  # ── HR / People ────────────────────────────────────────────────

  describe "HR/people terms" do
    test "pluralize" do
      assert Plurality.pluralize("person") == "people"
      assert Plurality.pluralize("child") == "children"
      assert Plurality.pluralize("man") == "men"
      assert Plurality.pluralize("woman") == "women"
      assert Plurality.pluralize("alumnus") == "alumni"
      assert Plurality.pluralize("persona") == "personas"
    end

    test "singularize" do
      assert Plurality.singularize("people") == "person"
      assert Plurality.singularize("children") == "child"
      assert Plurality.singularize("men") == "man"
      assert Plurality.singularize("women") == "woman"
      assert Plurality.singularize("alumni") == "alumnus"
    end
  end

  # ── Common irregulars ──────────────────────────────────────────

  describe "common irregulars" do
    test "pluralize" do
      assert Plurality.pluralize("mouse") == "mice"
      assert Plurality.pluralize("goose") == "geese"
      assert Plurality.pluralize("foot") == "feet"
      assert Plurality.pluralize("tooth") == "teeth"
      assert Plurality.pluralize("ox") == "oxen"
      assert Plurality.pluralize("die") == "dice"
      assert Plurality.pluralize("leaf") == "leaves"
      assert Plurality.pluralize("knife") == "knives"
      assert Plurality.pluralize("wolf") == "wolves"
      assert Plurality.pluralize("half") == "halves"
    end
  end

  # ── Latin / Greek ──────────────────────────────────────────────

  describe "Latin/Greek terms" do
    test "pluralize" do
      assert Plurality.pluralize("automaton") == "automata"
      assert Plurality.pluralize("polyhedron") == "polyhedra"
      assert Plurality.pluralize("corrigendum") == "corrigenda"
      assert Plurality.pluralize("alumnus") == "alumni"
      assert Plurality.pluralize("fungus") == "funguses"
      assert Plurality.pluralize("cactus") == "cactuses"
      assert Plurality.pluralize("genus") == "genera"
    end
  end

  # ── Edge cases ────────────────────────────────────────────────

  describe "edge cases" do
    test "pluralize(children, check: true) returns children" do
      assert Plurality.pluralize("children", check: true) == "children"
    end

    test "plural?(children) returns true" do
      assert Plurality.plural?("children") == true
    end

    test "plural?(people) returns true" do
      assert Plurality.plural?("people") == true
    end

    test "plural?(sheep) returns true" do
      assert Plurality.plural?("sheep") == true
    end

    test "singularize(taxes) returns tax, not taxis" do
      assert Plurality.singularize("taxes") == "tax"
    end

    test "pluralize(access) returns accesses, not access" do
      assert Plurality.pluralize("access") == "accesses"
    end

    test "pluralize(chassis) returns chassis (uncountable)" do
      assert Plurality.pluralize("chassis") == "chassis"
    end
  end
end
