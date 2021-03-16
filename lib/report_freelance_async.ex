defmodule ReportFreelanceAsync do
  alias ReportFreelanceAsync.Parser

  @months [
    "janeiro",
    "fevereiro",
    "marco",
    "abril",
    "maio",
    "junho",
    "julho",
    "agosto",
    "setembro",
    "outubro",
    "novembro",
    "dezembro"
  ]

  defp build(filename) do
    filename
    |> Parser.parse_file()
    |> Enum.reduce(report_acc(), fn line, report -> calc_hours(line, report) end)
  end

  def build_from_many(filenames) when not is_list(filenames) do
    {:error, "Please provide a list of strings"}
  end

  def build_from_many(filenames) do
    result =
      filenames
      |> Task.async_stream(&build/1)
      |> Enum.reduce(report_acc(), fn {:ok, result}, report -> sum_reports(report, result) end)

    {:ok, result}
  end

  defp calc_hours([name, hour, _day, month, year], %{
         "all_hours" => all_hours,
         "hours_per_month" => hours_per_month,
         "hours_per_year" => hours_per_year
       }) do
    key = String.downcase(name)

    all_hours = calc_all_hours(all_hours, key, hour)
    hours_per_month = calc_hours_per_month(hours_per_month, key, month, hour)
    hours_per_year = calc_hours_per_year(hours_per_year, key, year, hour)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp calc_all_hours(report, key, hour) do
    total_hours = get_total_hours(report[key])

    report
    |> Map.put(key, total_hours + hour)
  end

  defp calc_hours_per_month(report, key, month, hour) do
    user_key = get_user_key(report[key])
    month_key = Enum.at(@months, month - 1)
    total_hours = get_total_hours(report[key][month_key])

    months = Map.put(user_key, month_key, total_hours + hour)

    report
    |> Map.put(key, months)
  end

  defp calc_hours_per_year(report, key, year, hour) do
    user_key = get_user_key(report[key])
    total_hours = get_total_hours(report[key][year])

    years = Map.put(user_key, year, total_hours + hour)

    report
    |> Map.put(key, years)
  end

  defp get_total_hours(prev_hours), do: if(is_nil(prev_hours), do: 0, else: prev_hours)

  defp get_user_key(username), do: if(is_nil(username), do: %{}, else: username)

  defp report_acc, do: build_report(%{}, %{}, %{})

  defp build_report(all_hours, hours_per_month, hours_per_year),
    do: %{
      "all_hours" => all_hours,
      "hours_per_month" => hours_per_month,
      "hours_per_year" => hours_per_year
    }

  defp sum_reports(
         %{
           "all_hours" => all_hours1,
           "hours_per_month" => hours_per_month1,
           "hours_per_year" => hours_per_year1
         },
         %{
           "all_hours" => all_hours2,
           "hours_per_month" => hours_per_month2,
           "hours_per_year" => hours_per_year2
         }
       ) do
    all_hours = merge_maps(all_hours1, all_hours2)

    hours_per_month = merge_sub(hours_per_month1, hours_per_month2)
    hours_per_year = merge_sub(hours_per_year1, hours_per_year2)

    build_report(all_hours, hours_per_month, hours_per_year)
  end

  defp merge_maps(map1, map2) do
    Map.merge(map1, map2, fn _key, value1, value2 -> value1 + value2 end)
  end

  defp merge_sub(sub1, sub2) do
    Map.merge(sub1, sub2, fn _key, sub_map1, sub_map2 ->
      merge_maps(sub_map1, sub_map2)
    end)
  end
end
