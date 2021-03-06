# This file is maintained at http://git.mdcc.cx/caspar

# Copyright (C) 2012 Joost van Baal-Ilić <joostvb-caspar-c-12@mdcc.cx>
# Copyright (C) 2002, 2003, 2004, 2005, 2006, 2009, 2010 Joost van Baal <joostvb-caspar-c-12@mdcc.cx>
# Copyright © 2012,2014 Wessel Dankers <wsl-caspar-git-c@fruit.je>
#
# This file is part of caspar.  Caspar is free software; you can redistribute
# it and/or modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 3 of the License,
# or (at your option) any later version.  You should have received a copy of
# the GNU General Public License along with this file (see COPYING).

# see caspar(7) for usage

# possibility to choose own cp(1) and scp(1)
csp_CP         ?= cp
csp_SCP        ?= scp
csp_SUCP       ?= csp_sucp
csp_SSH        ?= ssh
csp_CAT        ?= cat
csp_Diff       ?= diff     # csp_DIFF is reserved for the user interface...
csp_RSYNC      ?= rsync
csp_MKDIRP     ?= mkdir -p
csp_INSTALL    ?= csp_install
csp_SCP_KEEP_MODE ?= csp_scp_keep_mode
csp_MKDIRCP    ?= csp_mkdircp

# extra arguments for cp(1) and scp(1)
csp_CPFLAGS    ?=
csp_SCPFLAGS   ?=
csp_RSYNCFLAGS ?= -zPt --chmod=ugo=rwX
csp_DIFFXARG   ?= -u

csp_EXTRAFILES ?=

csp_TABOOFILES_DEFAULT ?= Makefile .%.swp %~ \#%\# pod2htmd.tmp pod2htmi.tmp
csp_TABOOFILES ?= $(filter-out $(csp_TABOOFILES_SKIP),$(csp_TABOOFILES_DEFAULT)) $(csp_TABOOFILES_ADD)

csp_TABOODIRS_DEFAULT ?= CVS .svn
csp_TABOODIRS  ?= $(filter-out $(csp_TABOODIRS_SKIP),$(csp_TABOODIRS_DEFAULT)) $(csp_TABOODIRS_ADD)

# wrap csp_SCP and other puch mechanisms in make function template
csp_scp_FUNC    = $(csp_SCP) $(csp_SCPFLAGS) $(3) $(1):$(2)
csp_cp_FUNC     = $(csp_CP) $(csp_CPFLAGS) -t $(2) $(3)
csp_sucp_FUNC   = CSP_SUCP_USER=$(csp_SUCP_USER) $(csp_SUCP) $(1) $(2) $(3)
csp_rsync_FUNC  = $(csp_RSYNC) $(csp_RSYNCFLAGS) $(3) $(1)::$(2)
csp_rsyncssh_FUNC = $(csp_RSYNC) $(csp_RSYNCFLAGS) $(3) $(1):$(2)
csp_diff_FUNC   = $(csp_SSH) $(1) $(csp_CAT) $(2)/$(3) | $(csp_Diff) $(csp_DIFFXARG) - $(3)
csp_install_FUNC = $(csp_INSTALL) $(2) $(3)
csp_scp_keep_mode_FUNC = $(csp_SCP_KEEP_MODE) $(1) $(2) $(3)
csp_scpmkdir_FUNC = $(csp_SSH) $(1) $(csp_MKDIRP) $(2) && $(csp_scp_FUNC)
csp_mkdircp_FUNC = $(csp_MKDIRCP) $(2) $(3)

csp_PUSH       ?= $(csp_scp_FUNC)
csp_DIFF       ?= $(csp_diff_FUNC)

# we use plurals only
csp_UHOSTS     ?= $(csp_UHOST)

# uhosts that should be excluded for whatever reason
_csp_UHOSTS_COMPUTED := $(filter-out $(csp_UHOSTS_SKIP),$(csp_UHOSTS))
ifneq ($(csp_UHOSTS_SUBSET),)
_csp_UHOSTS_COMPUTED := $(filter $(csp_UHOSTS_SUBSET),$(_csp_UHOSTS_COMPUTED))
endif 

# files, not directories
_csp_FILES := $(shell for f in *; do test -f "$$f" && echo "$$f"; done)

# add built files, exclude editor backup files and other stuff
_csp_FILES := $(filter-out $(csp_TABOOFILES),$(_csp_FILES) $(csp_BUILD))

# user specified files
_csp_FILES := $(sort $(_csp_FILES) $(csp_EXTRAFILES))

all:
	$(MAKE) build
	$(MAKE) install
	$(MAKE) load

define _csp_filetargets
$1-install: $(foreach host,$(_csp_UHOSTS_COMPUTED),$1--$(host)--push)
$1-diff: $(foreach host,$(_csp_UHOSTS_COMPUTED),$1--$(host)--diff)
endef

define _csp_bulktargets
$2--bulk-push: $1
	$$(call csp_PUSH,$2,$$(csp_DIR),$1)
endef

$(foreach host,$(_csp_UHOSTS_COMPUTED),\
	$(eval $(call _csp_bulktargets,$(_csp_FILES),$(host))))

define _csp_remotetargets
$1--$2--push: $1
	$$(call csp_PUSH,$2,$$(csp_DIR),$1)

$1--$2--diff: $1
	$$(call csp_DIFF,$2,$$(csp_DIR),$1)
endef

$(foreach file,$(_csp_FILES),\
	$(eval $(call _csp_filetargets,$(file)))\
	$(foreach host,$(_csp_UHOSTS_COMPUTED),\
		$(eval $(call _csp_remotetargets,$(file),$(host)))))

define _csp_loadtarget
$1: $(patsubst %,$1--%--load,$(_csp_UHOSTS_COMPUTED))
endef

define _csp_loadtargets
$1--$2--load:
	$$(call $1,$2)
endef

$(foreach load,$(csp_LOAD),\
	$(eval $(call _csp_loadtarget,$(load)))\
	$(foreach host,$(_csp_UHOSTS_COMPUTED),\
		$(eval $(call _csp_loadtargets,$(load),$(host)))))

_csp_TARGETS := $(patsubst %,%-install,$(_csp_FILES))

_csp_BULKTARGETS := $(if $(_csp_FILES),$(patsubst %,%--bulk-push,$(_csp_UHOSTS_COMPUTED)))

_csp_DIFFTARGETS := $(patsubst %,%-diff,$(_csp_FILES))

_csp_LOADTARGETS := $(foreach load,$(csp_LOAD),$(load) $(patsubst %,$(load)--%--load,$(_csp_UHOSTS_COMPUTED)))

_csp_DIRS := $(shell for d in *; do test -d "$$d" && echo "$$d"; done)
_csp_DIRS := $(filter-out $(csp_TABOODIRS),$(_csp_DIRS))

define _csp_do_recursive
$1--install-recursive:
	$(MAKE) -C $1 install-recursive
endef

$(foreach dir,$(_csp_DIRS),$(eval $(call _csp_do_recursive,$(dir))))

build: $(csp_BUILD)

diff: $(_csp_DIFFTARGETS)

install: $(_csp_BULKTARGETS)

install-recursive: install $(patsubst %,%--install-recursive,$(_csp_DIRS))

load: $(csp_LOAD)

debug:
	@echo _csp_TARGETS $(_csp_TARGETS) _csp_BULKTARGETS $(_csp_BULKTARGETS) _csp_FILES $(_csp_FILES) csp_UHOSTS $(csp_UHOSTS) _csp_UHOSTS_COMPUTED $(_csp_UHOSTS_COMPUTED) csp_PUSH $(csp_PUSH)

.PHONY: $(csp_BUILD) $(_csp_TARGETS) $(_csp_BULKTARGETS) $(_csp_LOADTARGETS) $(_csp_DIFFTARGETS) build diff install install-recursive load debug
