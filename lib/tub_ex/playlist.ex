defmodule TubEx.Playlist do
  @moduledoc """
    Provide access to the `/playlists` are of YouTube API
  """

  @typedoc """
    Type that represents TubEx.Playlist struct.
  """
  @type t :: %TubEx.Playlist{
    id: charlist,
    kind: charlist,
    title: charlist,
    etag: charlist,
    resource_id: charlist,
    playlist_id: charlist,
    channel_id: charlist,
    channel_title: charlist,
    description: charlist,
    published_at: charlist,
    thumbnails: map,
  }
  defstruct [
    id: nil,
    kind: nil,
    title: nil,
    etag: nil,
    resource_id: nil,
    playlist_id: nil,
    channel_id: nil,
    channel_title: nil,
    description: nil,
    published_at: nil,
    thumbnails: %{}
  ]

  @doc """
    Fetch contents details

    Example:
      iex> TubEx.Playlist.get("PLZRRxQcaEjA5tpoxlKeVnPKIvfD1IavPq")
      { :ok, %TubEx.Playlist{} }
  """
  @spec get(charlist) :: { atom, TubEx.Video.t  }
  def get(playlist_id, opts \\ []) do
    defaults = [
      key: TubEx.api_key,
      id: playlist_id,
      part: "snippet",
    ]

    case api_request("/playlists", Keyword.merge(defaults, opts)) do
      {:ok, %{ "items" => [ %{ "snippet" => item, "etag" => etag } ] } } ->
        parse %{
          "etag" => etag,
          "snippet" => item,
          "id" => %{ "playlistId" => playlist_id }
        }
      err -> err
    end
  end

  @doc """
  Search from youtube via query.

  ## Examples

    ** Get playlists by query: **
      iex> TubEx.Playlist.search("The great debates")
      { :ok, [%TubEx.Playlist{}, ...], meta_map }

    ** Custom query parameters: **
      iex> TubEx.Playlist.search("The great debates", [
        paramKey: paramValue,
        ...
      ])
      { :ok, [%TubEx.Playlist{}, ...], meta_map }
  """
  @spec search(charlist, Keyword.t) :: { atom, list(TubEx.Video.t), map }
  def search(query, opts \\ []) do
    defaults = [
      key: TubEx.api_key,
      part: "snippet",
      maxResults: 20,
      q: query
    ]

    response = api_request("/search", Keyword.merge(defaults, opts))

    case response do
      {:ok, response} ->
        {:ok, Enum.map(response["items"], &parse!(&1, :playlist)), page_info(response)}
      err -> err
    end
  end

  def get_items(playlist_id, opts \\ []) do
    defaults = [
      key: TubEx.api_key(),
      part: "snippet",
      maxResults: 20,
      playlistId: playlist_id
    ]

    case api_request("/playlistItems", Keyword.merge(defaults, opts)) do
      {:ok, response} ->
        {:ok, Enum.map(response["items"], &(parse!(&1, :songs))), page_info(response)}
      err ->
        err
    end
  end

  defp api_request(pathname, query) do
    TubEx.API.get(
      TubEx.endpoint <> pathname,
      Keyword.merge(query, [type: "playlist"])
    )
  end

  defp page_info(response) do
    Map.merge(response["pageInfo"], %{
      "nextPageToken" => response["nextPageToken"],
      "prevPageToken" => response["prevPageToken"]
    })
  end

  defp parse!(body, type) do
    case parse(body, type) do
      {:ok, playlist} -> playlist
      {:error, body} ->
        raise "Parse error occured! #{Poison.Encoder.encode(body, %{})}"
    end
  end

  defp parse(%{"snippet" => snippet, "etag" => etag, "id" => %{"playlistId" => playlist_id}},
            :playlist) do
    {:ok,
      %TubEx.Playlist{
        etag: etag,
        title: snippet["title"],
        thumbnails: snippet["thumbnails"],
        published_at: snippet["publishedAt"],
        channel_title: snippet["channelTitle"],
        channel_id: snippet["channelId"],
        description: snippet["description"],
        playlist_id: playlist_id
      }
    }
  end

  defp parse(%{"etag" => etag, "id" => id, "kind" => kind, "snippet" => snippet},
            :songs) do
    {:ok,
      %TubEx.Playlist{
        etag: etag,
        kind: kind,
        id: id,
        channel_id: snippet["channelId"],
        channel_title: snippet["channelTitle"],
        description: snippet["description"],
        playlist_id: snippet["playlistId"],
        published_at: snippet["publishedAt"],
        resource_id: snippet["resourceId"],
        thumbnails: snippet["thumbnails"],
        title: snippet["title"]
      }
    }
  end

  defp parse(body) do
    {:error, body}
  end
end
