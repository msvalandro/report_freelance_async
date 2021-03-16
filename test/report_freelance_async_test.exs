defmodule ReportFreelanceAsyncTest do
  use ExUnit.Case

  describe "build_from_many/1" do
    test "when a files list is provided, builds the report" do
      filenames = ["part_test.csv", "part_test.csv"]

      response = ReportFreelanceAsync.build_from_many(filenames)

      expected_response =
        {:ok,
         %{
           "all_hours" => %{
             "cleiton" => 2,
             "daniele" => 24,
             "giuliano" => 18,
             "jakeliny" => 28,
             "joseph" => 6,
             "mayk" => 10
           },
           "hours_per_month" => %{
             "cleiton" => %{"junho" => 2},
             "daniele" => %{"abril" => 14, "dezembro" => 10},
             "giuliano" => %{"fevereiro" => 18},
             "jakeliny" => %{"julho" => 16, "marco" => 12},
             "joseph" => %{"marco" => 6},
             "mayk" => %{"dezembro" => 10}
           },
           "hours_per_year" => %{
             "cleiton" => %{2020 => 2},
             "daniele" => %{2016 => 10, 2018 => 14},
             "giuliano" => %{2017 => 6, 2019 => 12},
             "jakeliny" => %{2017 => 16, 2019 => 12},
             "joseph" => %{2017 => 6},
             "mayk" => %{2017 => 2, 2019 => 8}
           }
         }}

      assert response == expected_response
    end

    test "when a files list is not provided, returns an error" do
      filenames = "banana"

      response = ReportFreelanceAsync.build_from_many(filenames)

      expected_response = {:error, "Please provide a list of strings"}

      assert response == expected_response
    end
  end
end
