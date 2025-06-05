package telemetry

import (
	"context"
	"errors"
	"fmt"
	"go-hexagonal-fullstack-monorepo/internal/shared/fault"

	"go.opentelemetry.io/otel"
	"go.opentelemetry.io/otel/attribute"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace"
	"go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp"
	"go.opentelemetry.io/otel/propagation"
	"go.opentelemetry.io/otel/sdk/resource"
	"go.opentelemetry.io/otel/sdk/trace"
)

type OpenTelemetry struct {
	serviceName string
	endpoint    string
	env         string
}

func NewOpenTelemetry(serviceName, endpoint, env string) OpenTelemetry {
	return OpenTelemetry{
		serviceName: serviceName,
		endpoint:    endpoint,
		env:         env,
	}
}

// setupOTelSDK bootstraps the OpenTelemetry pipeline.
// If it does not return an error, make sure to call shutdown for proper cleanup.
func (o OpenTelemetry) Execute(ctx context.Context) (func(context.Context) error, error) {
	var shutdownFuncs []func(context.Context) error

	// shutdown calls cleanup functions registered via shutdownFuncs.
	// The errors from the calls are joined.
	// Each registered cleanup will be invoked once.
	shutdown := func(ctx context.Context) error {
		var err error
		for _, fn := range shutdownFuncs {
			err = errors.Join(err, fn(ctx))
		}
		shutdownFuncs = nil

		return fault.Wrap(err)
	}

	var err error

	// handleErr calls shutdown for cleanup and makes sure that all errors are returned.
	handleErr := func(inErr error) {
		err = errors.Join(inErr, shutdown(ctx))
	}

	// Set up propagator.
	prop := newPropagator()
	otel.SetTextMapPropagator(prop)

	// Set up trace provider.
	tracerProvider, err := newTraceProvider(ctx, o.serviceName, o.endpoint, o.env)
	if err != nil {
		handleErr(err)

		return shutdown, err
	}
	shutdownFuncs = append(shutdownFuncs, tracerProvider.Shutdown)
	otel.SetTracerProvider(tracerProvider)

	return shutdown, err
}

func newPropagator() propagation.TextMapPropagator {
	return propagation.NewCompositeTextMapPropagator(
		propagation.TraceContext{},
		propagation.Baggage{},
	)
}

func newTraceProvider(ctx context.Context, serviceName, endpoint, env string) (*trace.TracerProvider, error) {
	exporter, err := otlptrace.New(
		ctx,
		otlptracehttp.NewClient(
			otlptracehttp.WithInsecure(),
			otlptracehttp.WithEndpoint(endpoint),
		),
	)
	if err != nil {
		return nil, fault.Wrap(err)
	}

	resources, err := resource.New(
		ctx,
		resource.WithAttributes(
			attribute.String("service.name", fmt.Sprintf("%s-%s", serviceName, env)),
			attribute.String("library.language", "go"),
			attribute.String("env", env),
		),
	)
	if err != nil {
		return nil, fault.Wrap(err)
	}

	traceProvider := trace.NewTracerProvider(
		trace.WithSampler(trace.AlwaysSample()),
		trace.WithBatcher(exporter),
		trace.WithResource(resources),
	)

	return traceProvider, nil
}
