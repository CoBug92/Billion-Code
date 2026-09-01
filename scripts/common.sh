#!/bin/sh

set -eu

if [ -z "${SCRIPTS_DIRECTORY:-}" ]; then
    SCRIPTS_DIRECTORY="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
fi
PROJECT_DIRECTORY="$(CDPATH= cd -- "$SCRIPTS_DIRECTORY/.." && pwd)"

set -a
. "$SCRIPTS_DIRECTORY/.env"
set +a

export SCRIPTS_DIRECTORY PROJECT_DIRECTORY

select_simulator_destination() {
    if [ -n "${CI_XCODE_DESTINATION:-}" ]; then
        printf '%s\n' "$CI_XCODE_DESTINATION"
        return
    fi

    if ! simulator_json="$(xcrun simctl list devices available -j 2>/dev/null)"; then
        printf 'Unable to query available iPhone simulators. Check CoreSimulatorService.\n' >&2
        return 1
    fi

    printf '%s' "$simulator_json" | ruby -rjson -e '
      devices = JSON.parse(STDIN.read).fetch("devices")
      candidates = devices.flat_map do |runtime, entries|
        next [] unless runtime.include?("iOS")
        entries.filter_map do |device|
          next unless device["isAvailable"] && device["name"].start_with?("iPhone")
          [runtime, device]
        end
      end
      selected = candidates.max_by { |runtime, device| [runtime.scan(/\d+/).map(&:to_i), device["name"]] }
      abort "No available iPhone simulator was found" unless selected
      puts "platform=iOS Simulator,id=#{selected.last.fetch("udid")}"'
}
