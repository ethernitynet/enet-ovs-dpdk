#!/bin/bash

enet_run() {

	exec_tgt "${TGT_ENET_DIR}/AceNic_output" "\
		./AppInit_AceNic"
}
