-module(hex_api).
-export([
    default_options/0,
    get/1,
    get/2,
    get_package/1,
    get_package/2,
    get_release/2,
    get_release/3,
    get_user/1,
    get_user/2
]).

-type options() :: [{client, hex_http:client()} | {uri, binary()}].

%% @doc
%% Default options used to interact with the API.
%% @end
-spec default_options() -> options().
default_options() ->
    Client = #{adapter => hex_http_httpc, user_agent_fragment => <<"(httpc)">>},
    URI = <<"https://hex.pm/api">>,
    [{client, Client}, {uri, URI}].

-spec get(binary()) -> {ok, term()} | {error, term()}.
get(Path) when is_binary(Path) ->
    get(Path, default_options()).

-spec get(binary(), options()) -> {ok, term()} | {error, term()}.
get(Path, Options) when is_binary(Path) and is_list(Options) ->
    Client = proplists:get_value(client, Options),
    URI = proplists:get_value(uri, Options),
    Headers = #{<<"accept">> => <<"application/vnd.hex+erlang">>},

    case hex_http:get(Client, <<URI/binary, Path/binary>>, Headers) of
        {ok, {200, _, Body}} ->
            {ok, binary_to_term(Body)};

        {ok, {404, _, _Body}} ->
            {error, not_found};

        Other ->
            Other
    end.

%% @doc
%% Gets package.
%%
%% Examples:
%%
%% ```
%%     hex_api:get_package(<<"package">>).
%%     %%=> {ok, #{
%%     %%=>     <<"name">> => <<"package1">>,
%%     %%=>     <<"meta">> => #{
%%     %%=>         <<"description">> => ...,
%%     %%=>         <<"licenses">> => ...,
%%     %%=>         <<"links">> => ...,
%%     %%=>         <<"maintainers">> => ...
%%     %%=>     },
%%     %%=>     ...,
%%     %%=>     <<"releases">> => [
%%     %%=>         #{<<"url">> => ..., <<"version">> => <<"0.5.0">>}],
%%     %%=>         #{<<"url">> => ..., <<"version">> => <<"1.0.0">>}],
%%     %%=>         ...
%%     %%=>     ]}}
%% '''
%% @end
-spec get_package(binary()) -> {ok, map()} | {error, term()}.
get_package(Name) when is_binary(Name) ->
    get_package(Name, []).

%% @doc
%% Gets package.
%%
%% `Options` is merged with `default_options/0`.
%%
%% See `get_package/1' for examples.
-spec get_package(binary(), options()) -> {ok, map()} | {error, term()}.
get_package(Name, Options) when is_binary(Name) and is_list(Options) ->
    get(<<"/packages/", Name/binary>>, merge_with_default_options(Options)).

%% @doc
%% Gets package release.
%%
%% Examples:
%%
%% ```
%%     hex_api:get_release(<<"package">>, <<"1.0.0">>).
%%     %%=> {ok, #{
%%     %%=>     <<"version">> => <<"1.0.0">>,
%%     %%=>     <<"meta">> => #{
%%     %%=>         <<"description">> => ...,
%%     %%=>         <<"licenses">> => ...,
%%     %%=>         <<"links">> => ...,
%%     %%=>         <<"maintainers">> => ...
%%     %%=>     },
%%     %%=>     ...}}
%% '''
%% @end
-spec get_release(binary(), binary()) -> {ok, map()} | {error, term()}.
get_release(Name, Version) when is_binary(Name) and is_binary(Version) ->
    get_release(Name, Version, []).

-spec get_release(binary(), binary(), options()) -> {ok, map()} | {error, term()}.
get_release(Name, Version, Options) when is_binary(Name) and is_binary(Version) and is_list(Options) ->
    get(<<"/packages/", Name/binary, "/releases/", Version/binary>>, merge_with_default_options(Options)).

%% @doc
%% Gets user.
%%
%% Examples:
%%
%% ```
%%     hex_api:get_user(<<"user">>).
%%     %%=> {ok, #{
%%     %%=>     <<"username">> => <<"user">>,
%%     %%=>     <<"packages">> => [
%%     %%=>         #{
%%     %%=>             <<"name">> => ...,
%%     %%=>             <<"url">> => ...,
%%     %%=>             ...
%%     %%=>         },
%%     %%=>         ...
%%     %%=>     ],
%%     %%=>     ...}}
%% '''
%% @end
-spec get_user(binary()) -> {ok, map()} | {error, term()}.
get_user(Username) when is_binary(Username) ->
    get_user(Username, []).

%% @doc
%% Gets user.
%%
%% `Options` is merged with `default_options/0`.
%%
%% See `get_user/1' for examples.
-spec get_user(binary(), options()) -> {ok, map()} | {error, term()}.
get_user(Username, Options) when is_binary(Username) and is_list(Options) ->
    get(<<"/users/", Username/binary>>, merge_with_default_options(Options)).

%%====================================================================
%% Internal functions
%%====================================================================

merge_with_default_options(Options) when is_list(Options) ->
    lists:ukeymerge(1, lists:sort(Options), default_options()).