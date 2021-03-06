defmodule Benchee.Formatters.ConsoleTest do
  use ExUnit.Case, async: true
  doctest Benchee.Formatters.Console

  import ExUnit.CaptureIO
  alias Benchee.{Formatters.Console, Suite, Statistics, Benchmark.Scenario}

  @config %Benchee.Configuration{
    formatter_options: %{
      console: %{
        comparison: true,
        extended_statistics: false
      }
    },
    title: "A comprehensive benchmarking of inputs"
  }
  @no_input Benchee.Benchmark.no_input()

  describe ".output" do
    test "formats and prints the results right to the console" do
      scenarios = [
        %Scenario{
          name: "Second",
          input_name: @no_input,
          input: @no_input,
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 400.1},
            sample_size: 200
          },
          memory_usage_statistics: %Statistics{}
        },
        %Scenario{
          name: "First",
          input_name: @no_input,
          input: @no_input,
          run_time_statistics: %Statistics{
            average: 100.0,
            ips: 10_000.0,
            std_dev_ratio: 0.1,
            median: 90.0,
            percentiles: %{99 => 300.1},
            sample_size: 200
          },
          memory_usage_statistics: %Statistics{}
        }
      ]

      output =
        capture_io(fn ->
          Console.output(%Suite{scenarios: scenarios, configuration: @config})
        end)

      assert output =~ ~r/First/
      assert output =~ ~r/Second/
      assert output =~ ~r/200/
      assert output =~ ~r/5 K/
      assert output =~ ~r/10.00%/
      assert output =~ ~r/195.5/
      assert output =~ ~r/300.1/
      assert output =~ ~r/400.1/
    end
  end

  describe ".format" do
    @header_regex ~r/Name.+ips.+average.+deviation.+median.+99th %.*/
    test "with multiple inputs and just one job" do
      scenarios = [
        %Scenario{
          name: "Job",
          input_name: "My Arg",
          input: "My Arg",
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 400.1},
            sample_size: 200
          },
          memory_usage_statistics: %Statistics{}
        },
        %Scenario{
          name: "Job",
          input_name: "Other Arg",
          input: "Other Arg",
          run_time_statistics: %Statistics{
            average: 400.0,
            ips: 2_500.0,
            std_dev_ratio: 0.15,
            median: 395.0,
            percentiles: %{99 => 500.1},
            sample_size: 200
          },
          memory_usage_statistics: %Statistics{}
        }
      ]

      [my_arg, other_arg] = Console.format(%Suite{scenarios: scenarios, configuration: @config})

      [input_header, header, result] = my_arg
      assert input_header =~ "My Arg"
      assert header =~ @header_regex
      assert result =~ ~r/Job.+5.+200.+10\.00%.+195\.5.+400\.1/

      [input_header_2, header_2, result_2] = other_arg
      assert input_header_2 =~ "Other Arg"
      assert header_2 =~ @header_regex
      assert result_2 =~ ~r/Job.+2\.5.+400.+15\.00%.+395.+500\.1/
    end

    test "with multiple inputs and two jobs" do
      scenarios = [
        %Scenario{
          name: "Job",
          input_name: "My Arg",
          input: "My Arg",
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1},
            sample_size: 200
          },
          memory_usage_statistics: %Statistics{}
        },
        %Scenario{
          name: "Other Job",
          input_name: "My Arg",
          input: "My Arg",
          run_time_statistics: %Statistics{
            average: 100.0,
            ips: 10_000.0,
            std_dev_ratio: 0.3,
            median: 98.0,
            percentiles: %{99 => 200.1},
            sample_size: 200
          },
          memory_usage_statistics: %Statistics{}
        },
        %Scenario{
          name: "Job",
          input_name: "Other Arg",
          input: "Other Arg",
          run_time_statistics: %Statistics{
            average: 400.0,
            ips: 2_500.0,
            std_dev_ratio: 0.15,
            median: 395.0,
            percentiles: %{99 => 500.1},
            sample_size: 200
          },
          memory_usage_statistics: %Statistics{}
        },
        %Scenario{
          name: "Other Job",
          input_name: "Other Arg",
          input: "Other Arg",
          run_time_statistics: %Statistics{
            average: 250.0,
            ips: 4_000.0,
            std_dev_ratio: 0.31,
            median: 225.5,
            percentiles: %{99 => 300.1},
            sample_size: 200
          },
          memory_usage_statistics: %Statistics{}
        }
      ]

      [my_arg, other_arg] = Console.format(%Suite{scenarios: scenarios, configuration: @config})

      [input_header, _header, other_job, job, _comp, ref, slower] = my_arg
      assert input_header =~ "My Arg"
      assert other_job =~ ~r/Other Job.+10.+100.+30\.00%.+98.+200\.1/
      assert job =~ ~r/Job.+5.+200.+10\.00%.+195\.5/
      ref =~ ~r/Other Job/
      slower =~ ~r/Job.+slower/

      [input_header_2, _, other_job_2, job_2, _, ref_2, slower_2] = other_arg
      assert input_header_2 =~ "Other Arg"
      assert other_job_2 =~ ~r/Other Job.+4.+250.+31\.00%.+225\.5.+300\.1/
      assert job_2 =~ ~r/Job.+2\.5.+400.+15\.00%.+395/
      ref_2 =~ ~r/Other Job/
      slower_2 =~ ~r/Job.+slower/
    end

    test "with and without a tag" do
      scenarios = [
        %Scenario{
          name: "job",
          input_name: @no_input,
          input: @no_input,
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1},
            sample_size: 200
          },
          memory_usage_statistics: %Statistics{}
        },
        %Scenario{
          name: "job (improved)",
          input_name: @no_input,
          input: @no_input,
          run_time_statistics: %Statistics{
            average: 100.0,
            ips: 10_000.0,
            std_dev_ratio: 0.1,
            median: 90.0,
            percentiles: %{99 => 200.1},
            sample_size: 200
          },
          memory_usage_statistics: %Statistics{}
        }
      ]

      [result] = Console.format(%Suite{scenarios: scenarios, configuration: @config})
      [_, _header, job_with_tag, job, _, comparison, _slower] = result

      assert job_with_tag =~ ~r/job \(improved\)\s+10 K/
      assert job =~ ~r/job\s+5 K/
      assert comparison =~ ~r/job \(improved\)\s+ 10 K/
    end

    test "includes the suite's title" do
      scenarios = [
        %Scenario{
          name: "job",
          input_name: @no_input,
          input: @no_input,
          run_time_statistics: %Statistics{
            average: 200.0,
            ips: 5_000.0,
            std_dev_ratio: 0.1,
            median: 195.5,
            percentiles: %{99 => 300.1},
            sample_size: 200
          },
          memory_usage_statistics: %Statistics{}
        }
      ]

      [[title | _]] = Console.format(%Suite{scenarios: scenarios, configuration: @config})

      assert title =~ ~r/A comprehensive benchmarking of inputs/
    end
  end
end
