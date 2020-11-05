       _____                          _      _ _    ___
      / ____|                        | |    (_) |  |__ \
     | |     ___  _ __ ___  _ __ ___ | |     _| |__   ) |
     | |    / _ \| '_ ` _ \| '_ ` _ \| |    | | '_ \ / /
     | |___| (_) | | | | | | | | | | | |____| | |_) / /_
      \_____\___/|_| |_| |_|_| |_| |_|______|_|_.__/____|



#### Introduction

This is a reverse-engineered copy of the commlib2 library created by İlker Fıçıcılar. You can find instructions on his website here: http://cbm.ficicilar.name.tr/program/7/rs232-communication-library

To build, just run `make`. You will need to have `make` and `docker` installed since it uses my kickassembler docker image.

The library loads at $ca00 and should be relocatable. It creates a receive buffer at $9000, so if you're going to use it with BASIC, you'll need to lower the top of BASIC with `poke 56,144:clr` before loading the library.
