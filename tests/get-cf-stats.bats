#!/usr/bin/env bats

load "helpers/print"

source "$BATS_TEST_DIRNAME/../src/get-cf-usage.sh"

function cf() {
  echo "cf $@" >> $__cf_out
}

function setup() {
  export __output=$BATS_TEST_DIRNAME/output
  export __report=$BATS_TEST_DIRNAME/report
  export __config=$BATS_TEST_DIRNAME/config
  export __assets=$BATS_TEST_DIRNAME/assets

  export __cf_out=$__output/cf.out.$BATS_TEST_NUMBER

  rm -rf $__cf_out $__report $__config
  mkdir -p $__config $__report $__output
}

@test "Should login properly" {
  REPORT_NAME=report CF_ENDPOINT='api.cf.local' CF_USERNAME=username CF_PASSWORD=password run get-cf-usage

  [ $status -eq 0 ]

  grep -q 'cf api api.cf.local' $__cf_out
  grep -q 'cf auth username password' $__cf_out
}

@test "Should not print password" {
  REPORT_NAME=report CF_ENDPOINT='api.cf.local' CF_USERNAME=username CF_PASSWORD=password run get-cf-usage

  [ $status -eq 0 ]

  function foo() { echo $output | grep -q 'password'; }

  run "foo"
  [ $status -ne 0 ]
}

@test "Should install plugin" {
  REPORT_NAME=report PLUGIN_PATH=plugin-linux run get-cf-usage

  [ $status -eq 0 ]

  grep -q 'cf install-plugin -f plugin/plugin-linux' $__cf_out
}

@test "Should output report" {
  REPORT_NAME=report run get-cf-usage

  [ $status -eq 0 ]

  grep -q 'cf bcr --ai --si' $__cf_out
  [ -f $__report/report.txt ]
}

@test "Should output monthly report" {
  MONTHLY=true REPORT_NAME=report-monthly run get-cf-usage

  [ $status -eq 0 ]

  grep -q 'cf bcr --monthly --ai --si' $__cf_out
  [ -f $__report/report-monthly.txt ]
}

@test "Should pull configurations from a config file" {
  cp $__assets/single.yml $__config/single.yml

  REPORT_NAME=report CONFIG_PATH=single.yml run get-cf-usage

  [ $status -eq 0 ]

  grep -q 'cf api cf.local --skip-ssl-validation' $__cf_out
  grep -q 'cf auth username password' $__cf_out

  [ -f $__report/single-test.txt ]
}

@test "Should pull multiple configurations from a config file" {
  cp $__assets/multiple.yml $__config/multiple.yml

  REPORT_NAME=report CONFIG_PATH=multiple.yml run get-cf-usage

  [ $status -eq 0 ]

  grep -q 'cf api cf.local --skip-ssl-validation' $__cf_out
  grep -q 'cf auth username password' $__cf_out

  grep -q 'cf api cf2.local --skip-ssl-validation' $__cf_out
  grep -q 'cf auth username2 password2' $__cf_out

  [ -f $__report/multiple-test.txt ]
}
