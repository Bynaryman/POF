#!/bin/bash
sby -f quire.sby
gtkwave quire/engine_0/trace0.vcd quire.gtkw
