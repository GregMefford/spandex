defmodule Spandex.TraceDecorator do
  @moduledoc """

  defmodule Foo do
    use Spandex.TraceDecorator

    @decorate traced()
    def bar(a) do
      a * 2
    end

    @decorate traced(service: "ecto", type: "sql")
    def databaz(a) do
      a * 3
    end
  end
  """
  use Decorator.Define, [traced: 0, traced: 1]

  def traced(body, context) do
    if Application.get_env(:spandex, :disabled?) do
      quote do
        unquote(body)
      end
    else
      quote do
        name = "#{unquote(context.name)}/#{unquote(context.arity)}"
        Spandex.Trace.start_span(name)

        try do
          return_value = unquote(body)
          Spandex.Trace.end_span()
          return_value
        rescue
          exception ->
            Spandex.Trace.span_error(exception)
          raise exception
        end
      end
    end
  end

  def traced(attributes, body, context) do
    if Application.get_env(:spandex, :disabled?) do
      quote do
        unquote(body)
      end
    else
      quote do
        attributes = unquote(attributes)
        name = attributes[:name] || "#{unquote(context.name)}/#{unquote(context.arity)}"
        Spandex.Trace.start_span(name)

        Spandex.Trace.update_span(attributes |> Enum.into(%{}))

        try do
          return_value = unquote(body)
          Spandex.Trace.end_span()
          return_value
        rescue
          exception ->
            Spandex.Trace.span_error(exception)
          raise exception
        end
      end
    end
  end
end
