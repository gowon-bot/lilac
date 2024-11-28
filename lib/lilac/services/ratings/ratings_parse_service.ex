defmodule Lilac.Ratings.Parse do
  alias Lilac.Ratings.Parse.Types.RawRatingRow
  alias Lilac.Lilac.Sync.Conversion.Cache

  @localized_parts_regex ~r/\[(.*?)\]/
  @unlocalized_parts_regex ~r/(.*?)\s*\[.*?\]/

  @separators_regex ~r/( & |, | \/ | \+ | X | x)/
  @separators_no_brackets_regex ~r/( & |, | \/ | \+ | X | x )(?![^\[]*\])/

  @title_brackets_regex ~r/^(.*) \((.*)\)$/

  # Since we're generating all possible combinations of artists and titles
  # we need to limit the number of albums we generate to avoid combinatorial explosion
  @max_combinatorical_input 5
  @max_permutations_count 1000

  # Define headers
  @headers %{
    rymID: "RYM Album",
    firstName: "First Name",
    lastName: "Last Name",
    firstNameLocalized: "First Name localized",
    lastNameLocalized: "Last Name localized",
    title: "Title",
    releaseDate: "Release_Date",
    rating: "Rating"
  }

  @spec parse_csv(String.t()) :: {:ok, [RawRatingRow.t()]} | {:error, String.t()}
  def parse_csv(csvstring) do
    if !headers_correct?(csvstring) do
      Lilac.Errors.Ratings.csv_not_in_correct_format()
    else
      {
        :ok,
        csvstring
        |> String.split("\n")
        |> Stream.map(&(&1 <> "\n"))
        |> CSV.decode!(headers: true, unredact_exceptions: true, field_transform: &String.trim/1)
        |> Enum.to_list()
        |> only_rated_rows()
        |> Enum.map(&parse_row/1)
      }
    end
  end

  @spec generate_album_combinations(RawRatingRow.t()) :: [Cache.raw_album()]
  def generate_album_combinations(rating_row) do
    parse_artist_names(rating_row.artist_name, rating_row.artist_name_localized)
    |> generate_permutations(parse_release_title(rating_row.title))
    |> Enum.take(@max_permutations_count)
    |> add_raw_artists(rating_row)
    |> add_single_and_split(rating_row)
    |> map_to_raw_album()
  end

  @spec parse_release_title(String.t()) :: [String.t()]
  defp parse_release_title(release_title) do
    case Regex.run(@title_brackets_regex, release_title) do
      [_, title1, title2] ->
        if not String.contains?(String.downcase(title2), "version") do
          [title1, title2]
        else
          [release_title]
        end

      _ ->
        [release_title]
    end
  end

  @spec parse_row(CSV.Row.t()) :: RawRatingRow.t()
  defp parse_row(row) do
    {localized_name, unlocalized_name} =
      get_localized_and_unlocalized(row)

    %RawRatingRow{
      rym_id: row[@headers.rymID],
      artist_name: unlocalized_name,
      artist_name_localized: localized_name,
      title: unescape(row[@headers.title]),
      release_year:
        if(row[@headers.releaseDate] == "",
          do: -1,
          else: String.to_integer(row[@headers.releaseDate])
        ),
      rating: row[@headers.rating]
    }
  end

  @spec only_rated_rows(CSV.t()) :: CSV.t()
  defp only_rated_rows(csv) do
    csv |> Enum.filter(fn row -> row[@headers.rating] != "0" end)
  end

  @spec unescape(String.t()) :: String.t()
  defp unescape(str) do
    str |> String.replace(~r/&amp;/, "&") |> String.replace(~r/&#34;/, "\"")
  end

  @spec combine_names(String.t(), String.t()) :: String.t()
  defp combine_names(first_name, last_name) do
    name = first_name

    if name != "" && last_name != "" do
      name <> " " <> last_name
    else
      last_name
    end
  end

  @spec add_raw_artists([{[String.t()], String.t()}], RawRatingRow.t()) :: [
          {[String.t()], String.t()}
        ]
  defp add_raw_artists(permutations, rating_row) do
    permutations ++
      create_artist_title_combos(
        [
          [rating_row.artist_name],
          [rating_row.artist_name_localized]
        ]
        |> Enum.reject(fn alist -> Enum.at(alist, 0) == "" end),
        parse_release_title(rating_row.title)
      )
  end

  defp add_single_and_split(permutations, rating_row) do
    permutations ++
      create_artist_title_combos(
        (split_on_and(rating_row.artist_name) ++ split_on_and(rating_row.artist_name_localized))
        |> Enum.map(fn a -> [a] end)
        |> Enum.reject(fn alist -> Enum.at(alist, 0) == "" end),
        parse_release_title(rating_row.title)
      )
  end

  defp parse_artist_names(artist_name, artist_name_localized) do
    (split_on_common_separators(artist_name) ++
       if(!is_nil(artist_name_localized),
         do: split_on_common_separators(artist_name_localized),
         else: []
       ))
    #  split_on_common_separators(artist_name_localized)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  # Generate all ordered permutations of artists and titles
  # eg if artists was {artist1, artist2} and titles was {title1, title2}
  # the result would be:
  # [{{artist1}, {title1}}, {{artist1, artist2}, {title1}}, {{artist2, artist1}, {title1}}, {{artist2}, {title1}},]
  @spec generate_permutations([String.t()], [String.t()]) :: [{[String.t()], String.t()}]
  defp generate_permutations(artists, titles) do
    # Limit the number of artists we generate combinations for to avoid combinatorial explosion
    artist_count = min(length(artists), @max_combinatorical_input)

    Enum.flat_map(1..artist_count, fn n ->
      Lilac.Permutations.permutations(artists, n)
    end)
    |> Enum.uniq()
    |> create_artist_title_combos(titles)
  end

  @spec create_artist_title_combos([String.t()], [String.t()]) :: [{[String.t()], String.t()}]
  defp create_artist_title_combos(artists, titles) do
    for artist <- artists, title <- titles do
      {artist, title}
    end
  end

  @spec split_on_common_separators(String.t()) :: [String.t()]
  defp split_on_common_separators(artist_name) do
    @separators_regex |> Regex.split(artist_name)
  end

  @spec split_on_common_separators_no_brackets(String.t()) :: [String.t()]
  defp split_on_common_separators_no_brackets(artist_name) do
    Regex.split(@separators_no_brackets_regex, artist_name)
  end

  @spec split_on_and(String.t()) :: [String.t()]
  defp split_on_and(artist_name) do
    ~r/( & )/ |> Regex.split(artist_name)
  end

  @spec map_to_raw_album([{[String.t()], String.t()}]) :: [Cache.raw_album()]
  defp map_to_raw_album(permutations) do
    permutations
    |> Enum.reject(fn {artists, _} ->
      artists |> Enum.any?(&is_nil/1) || length(artists) == 0
    end)
    |> Enum.map(fn {artists, title} ->
      {join_artists(artists), title}
    end)
  end

  defp join_artists(artists) do
    case length(artists) do
      1 ->
        artists |> List.first()

      2 ->
        Enum.at(artists, 0) <> " & " <> Enum.at(artists, 1)

      _ ->
        second_last_index = length(artists) - 2
        Enum.join(Enum.slice(artists, 0..second_last_index), ", ") <> " & " <> List.last(artists)
    end
  end

  @spec get_localized_and_unlocalized(RawRatingRow.t()) :: {String.t(), String.t() | nil}
  defp get_localized_and_unlocalized(row) do
    artist_name = unescape(combine_names(row[@headers.firstName], row[@headers.lastName]))

    localized_artist_name =
      unescape(combine_names(row[@headers.firstNameLocalized], row[@headers.lastNameLocalized]))

    if localized_artist_name == "" do
      extract_localized_and_unlocalized(artist_name)
    else
      {localized_artist_name, artist_name}
    end
  end

  @spec extract_localized_and_unlocalized(String.t()) :: {String.t(), String.t()}
  defp extract_localized_and_unlocalized(artist_name) do
    parts = split_on_common_separators_no_brackets(artist_name)

    localized_parts =
      Enum.map(parts, fn part ->
        case Regex.run(@localized_parts_regex, part) do
          [_, unlocalized] -> unlocalized
          _ -> part
        end
      end)

    unlocalized_parts =
      Enum.map(parts, fn part ->
        case Regex.run(@unlocalized_parts_regex, part) do
          [_, localized] -> localized
          _ -> part
        end
      end)

    localized_string = join_with_separators(localized_parts, artist_name)
    unlocalized_string = join_with_separators(unlocalized_parts, artist_name)

    {localized_string, unlocalized_string}
  end

  @spec join_with_separators([String.t()], String.t()) :: String.t()
  defp join_with_separators(parts, original_string) do
    separators =
      Regex.scan(@separators_no_brackets_regex, original_string)
      |> Enum.map(fn [match, _] -> match end)

    Enum.zip(parts, separators ++ [""])
    |> Enum.map(fn {part, sep} -> part <> sep end)
    |> Enum.join()
  end

  @spec headers_correct?(String.t()) :: boolean()
  defp headers_correct?(csvstring) do
    headers =
      csvstring
      |> String.split("\n")
      |> List.first()
      |> String.split(",")
      |> Enum.map(&String.trim/1)

    Enum.all?(@headers, fn {_, value} -> Enum.member?(headers, value) end)
  end
end
