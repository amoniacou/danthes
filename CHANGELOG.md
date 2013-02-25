# d'Anthès

## 1.0.4 (February 25 2013)

* Added possibility to activate Faye's subscription later on subscribe call

## 1.0.3 (September 26 2012)

* Fix IE support

## 1.0.2 (September 7 2012)

* Subscription callback through sign call
* On subscription connect callback
* On subscription error callback
* Transport disabling

## 1.0.1 (August 26 2012)

* Generator for redis config file
* Fixes for rackup file
* Fixes for full server url
* CoffeeScript class documentation

## 1.0 (August 25 2012)

* initial release


# PrivatePub

## 1.0.0 (January 25, 2012)

* Rails 3.2 compatibility with SecureRandom fix (thanks windigo) - issue #26

## 1.0.0 (January 15, 2012)

* setting config defaults to nil so everything must be set in `private_pub.yml`

* Documentation improvements


## 0.3.0 (January 14, 2012)

* adding `PrivatePub.publish_to` method for publishing from anywhere - issue #15

* rewriting `private_pub.js` so it is framework agnostic

* Rails 3.1 compatibility (thanks BinaryMuse) - issue #25

* adding faye gem dependency so it doesn't need to be installed separately

* renaming `faye.ru` to `private_pub.ru`

* truncate token for client for security (thanks jameshuynh) - issue #19


## 0.2.0 (April 7, 2011)

* switched to YAML file for config. BACKWARDS INCOMPATIBLE: you will need to remove config/initializers/private_pub.rb

* moved view helpers into Railtie so helper file is no longer generated

* error out when signature has expired


## 0.1.0 (April 4, 2011)

* initial release
