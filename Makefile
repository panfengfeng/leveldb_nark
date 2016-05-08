# Copyright (c) 2011 The LevelDB Authors. All rights reserved.
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE file. See the AUTHORS file for names of contributors.

# Inherit some settings from environment variables, if available
INSTALL_PATH ?= $(CURDIR)

#-----------------------------------------------
# Uncomment exactly one of the lines labelled (A), (B), and (C) below
# to switch between compilation modes.

OPT ?= -O2 -fno-omit-frame-pointer -DNDEBUG       # (A) Production use (optimized mode)
#OPT ?= -g2              # (B) Debug mode, w/ full line-level debugging symbols
#OPT ?= -O2 -g2 -DNDEBUG # (C) Profiling mode: opt, but w/debugging symbols
#-----------------------------------------------

# detect what platform we're building on
$(shell ./build_detect_platform build_config.mk)
# this file is generated by the previous line to set build flags and sources
include build_config.mk

#ROCKDB_NEW_INCLUDE_PATH=-I/data/dbengine/rocksdb-4.1/include
#librocksdb-4.1.so 
ROCKDB_NEW_INCLUDE_PATH=-I/data/dbengine/rocksdb-4.4/include
#librocksdb-4.4.so 

REDIS_INCLUDE_PATH=-I/data/dbengine/hiredis-0.13.3

WIREDTIGER_INCLUDE_PATH=-I/data/dbengine/wiredtiger-2.8.0
#libwiredtiger-2.8.0.so, libbwiredtiger_snappy.so

TERARKDB_INCLUDE_PATH=-I/data/dbengine/terark/terark-db/src -I/data/dbengine/terark/terark-db/terark-base/src

CFLAGS += -I. -I./include $(PLATFORM_CCFLAGS) $(OPT)
#CXXFLAGS += -I. -I./include $(ROCKDB_NEW_INCLUDE_PATH) $(WIREDTIGER_INCLUDE_PATH) $(REDIS_INCLUDE_PATH) $(TERARKDB_INCLUDE_PATH) $(PLATFORM_CXXFLAGS) $(OPT) -std=gnu++14
CXXFLAGS += -I. -I./include $(ROCKDB_NEW_INCLUDE_PATH) $(WIREDTIGER_INCLUDE_PATH) $(REDIS_INCLUDE_PATH) $(TERARKDB_INCLUDE_PATH) $(PLATFORM_CXXFLAGS) $(OPT) -Woverloaded-virtual -Wnon-virtual-dtor -Wno-missing-field-initializers


LDFLAGS += $(PLATFORM_LDFLAGS)
#LDFLAGS += -L/opt/lib

LIBOBJECTS = $(SOURCES:.cc=.o)
MEMENVOBJECTS = $(MEMENV_SOURCES:.cc=.o)

TESTUTIL = ./util/testutil.o
TESTHARNESS = ./util/testharness.o $(TESTUTIL)

TESTS = \
	arena_test \
	bloom_test \
	c_test \
	cache_test \
	coding_test \
	corruption_test \
	crc32c_test \
	db_test \
	dbformat_test \
	env_test \
	filename_test \
	filter_block_test \
	log_test \
	memenv_test \
	skiplist_test \
	table_test \
	version_edit_test \
	version_set_test \
	write_batch_test

PROGRAMS = db_bench $(TESTS)
BENCHMARKS = db_bench_bdb db_bench_leveldb db_bench_mdb db_bench_sqlite3 \
	     db_bench_tree_db db_bench_wiredtiger db_bench_redis \
	     db_bench_terark_index db_bench_rocksdb_new \
	     db_movies_leveldb db_movies_terark_index db_movies_rocksdb db_movies_redis db_movies_wiredtiger_overwrite \
	     db_pagecounts_terark_index db_pagecounts_rocksdb db_pagecounts_redis db_pagecounts_wiredtiger_overwrite \
	     db_humangenome_terark_index db_humangenome_rocksdb db_humangenome_redis db_humangenome_wiredtiger_overwrite \
	    db_wikiarticles_terark_index db_wikiarticles_rocksdb db_wikiarticles_redis db_wikiarticles_wiredtiger_overwrite \

LIBRARY = libleveldb.a
MEMENVLIBRARY = libmemenv.a

default: all

# Should we build shared libraries?
ifneq ($(PLATFORM_SHARED_EXT),)

ifneq ($(PLATFORM_SHARED_VERSIONED),true)
SHARED1 = libleveldb.$(PLATFORM_SHARED_EXT)
SHARED2 = $(SHARED1)
SHARED3 = $(SHARED1)
SHARED = $(SHARED1)
else
# Update db.h if you change these.
SHARED_MAJOR = 1
SHARED_MINOR = 5
SHARED1 = libleveldb.$(PLATFORM_SHARED_EXT)
SHARED2 = $(SHARED1).$(SHARED_MAJOR)
SHARED3 = $(SHARED1).$(SHARED_MAJOR).$(SHARED_MINOR)
SHARED = $(SHARED1) $(SHARED2) $(SHARED3)
$(SHARED1): $(SHARED3)
	ln -fs $(SHARED3) $(SHARED1)
$(SHARED2): $(SHARED3)
	ln -fs $(SHARED3) $(SHARED2)
endif

$(SHARED3):
	$(CXX) $(LDFLAGS) $(PLATFORM_SHARED_LDFLAGS)$(SHARED2) $(CXXFLAGS) $(PLATFORM_SHARED_CFLAGS) $(SOURCES) -o $(SHARED3)

endif  # PLATFORM_SHARED_EXT

all: $(SHARED) $(LIBRARY)

check: all $(PROGRAMS) $(TESTS)
	for t in $(TESTS); do echo "***** Running $$t"; ./$$t || exit 1; done

clean:
	-rm -f $(PROGRAMS) $(BENCHMARKS) $(LIBRARY) $(SHARED) $(MEMENVLIBRARY) */*.o */*/*.o ios-x86/*/*.o ios-arm/*/*.o build_config.mk
	-rm -rf ios-x86/* ios-arm/*

$(LIBRARY): $(LIBOBJECTS)
	rm -f $@
	$(AR) -rs $@ $(LIBOBJECTS)

db_bench_mdb: doc/bench/db_bench_mdb.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/bench/db_bench_mdb.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -llmdb

db_bench_sqlite3: doc/bench/db_bench_sqlite3.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/bench/db_bench_sqlite3.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lsqlite3

db_bench_tree_db: doc/bench/db_bench_tree_db.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/bench/db_bench_tree_db.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lkyotocabinet

db_bench_bdb: doc/bench/db_bench_bdb.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/bench/db_bench_bdb.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -ldb-5.3


db_bench_leveldb: doc/bench/db_bench_leveldb.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/bench/db_bench_leveldb.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS)

db_bench_wiredtiger: doc/bench/db_bench_wiredtiger.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/bench/db_bench_wiredtiger.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lwiredtiger-2.8.0 -lwiredtiger_snappy

db_bench_rocksdb_new: doc/bench/db_bench_rocksdb_new.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/bench/db_bench_rocksdb_new.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lrocksdb-4.4

db_bench_redis: doc/bench/db_bench_redis.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/bench/db_bench_redis.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lhiredis

db_bench_terark_index: doc/bench/db_bench_terark_index.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/bench/db_bench_terark_index.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lterark-fsa_all-g++-5.3-r -lterark-db-g++-5.3-r -lboost_system -lboost_filesystem -lwiredtiger-2.8.0 -ltbb

db_movies_terark_index: doc/movies/db_movies_terark_index.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/movies/db_movies_terark_index.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lterark-fsa_all-g++-5.3-r -lterark-db-g++-5.3-r -lboost_system -lboost_filesystem -lwiredtiger-2.8.0 -ltbb -lrt

db_movies_wiredtiger_overwrite: doc/movies/db_movies_wiredtiger_overwrite.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/movies/db_movies_wiredtiger_overwrite.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lwiredtiger-2.8.0 -lwiredtiger_snappy -lrt

db_movies_redis: doc/movies/db_movies_redis.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/movies/db_movies_redis.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lhiredis

db_movies_leveldb: doc/movies/db_movies_leveldb.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/movies/db_movies_leveldb.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lrt

db_movies_rocksdb: doc/movies/db_movies_rocksdb.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/movies/db_movies_rocksdb.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lrocksdb-4.4 -lrt

db_humangenome_terark_index: doc/humangenome/db_humangenome_terark_index.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/humangenome/db_humangenome_terark_index.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lterark-fsa_all-g++-5.3-r -lterark-db-g++-5.3-r -lboost_system -lboost_filesystem -lwiredtiger-2.8.0 -ltbb

db_humangenome_wiredtiger_overwrite: doc/humangenome/db_humangenome_wiredtiger_overwrite.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/humangenome/db_humangenome_wiredtiger_overwrite.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lwiredtiger-2.8.0 -lwiredtiger_snappy

db_humangenome_redis: doc/humangenome/db_humangenome_redis.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/humangenome/db_humangenome_redis.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lhiredis

db_humangenome_rocksdb: doc/humangenome/db_humangenome_rocksdb.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/humangenome/db_humangenome_rocksdb.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lrocksdb-4.1

db_pagecounts_terark_index: doc/pagecounts/db_pagecounts_terark_index.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/pagecounts/db_pagecounts_terark_index.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lterark-fsa_all-g++-5.3-r -lterark-db-g++-5.3-r -lboost_system -lboost_filesystem -lwiredtiger-2.8.0 -ltbb

db_pagecounts_wiredtiger_overwrite: doc/pagecounts/db_pagecounts_wiredtiger_overwrite.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/pagecounts/db_pagecounts_wiredtiger_overwrite.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lwiredtiger-2.8.0 -lwiredtiger_snappy

db_pagecounts_redis: doc/pagecounts/db_pagecounts_redis.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/pagecounts/db_pagecounts_redis.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lhiredis

db_pagecounts_rocksdb: doc/pagecounts/db_pagecounts_rocksdb.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/pagecounts/db_pagecounts_rocksdb.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lrocksdb-4.1

db_wikiarticles_terark_index: doc/wikiarticles/db_wikiarticles_terark_index.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/wikiarticles/db_wikiarticles_terark_index.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lterark-fsa_all-g++-5.3-r -lterark-db-g++-5.3-r -lboost_system -lboost_filesystem -lwiredtiger-2.8.0 -ltbb

db_wikiarticles_rocksdb: doc/wikiarticles/db_wikiarticles_rocksdb.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/wikiarticles/db_wikiarticles_rocksdb.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lrocksdb-4.1

db_wikiarticles_wiredtiger_overwrite: doc/wikiarticles/db_wikiarticles_wiredtiger_overwrite.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/wikiarticles/db_wikiarticles_wiredtiger_overwrite.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lwiredtiger-2.8.0 -lwiredtiger_snappy

db_wikiarticles_redis: doc/wikiarticles/db_wikiarticles_redis.o $(LIBOBJECTS) $(TESTUTIL)
	$(CXX) doc/wikiarticles/db_wikiarticles_redis.o $(LIBOBJECTS) $(TESTUTIL) -o $@ $(LDFLAGS) -lhiredis

arena_test: util/arena_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) util/arena_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

bloom_test: util/bloom_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) util/bloom_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

c_test: db/c_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) db/c_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

cache_test: util/cache_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) util/cache_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

coding_test: util/coding_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) util/coding_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

corruption_test: db/corruption_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) db/corruption_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

crc32c_test: util/crc32c_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) util/crc32c_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

db_test: db/db_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) db/db_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

dbformat_test: db/dbformat_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) db/dbformat_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

env_test: util/env_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) util/env_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

filename_test: db/filename_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) db/filename_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

filter_block_test: table/filter_block_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) table/filter_block_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

log_test: db/log_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) db/log_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

table_test: table/table_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) table/table_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

skiplist_test: db/skiplist_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) db/skiplist_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

version_edit_test: db/version_edit_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) db/version_edit_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

version_set_test: db/version_set_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) db/version_set_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

write_batch_test: db/write_batch_test.o $(LIBOBJECTS) $(TESTHARNESS)
	$(CXX) db/write_batch_test.o $(LIBOBJECTS) $(TESTHARNESS) -o $@ $(LDFLAGS)

$(MEMENVLIBRARY) : $(MEMENVOBJECTS)
	rm -f $@
	$(AR) -rs $@ $(MEMENVOBJECTS)

memenv_test : helpers/memenv/memenv_test.o $(MEMENVLIBRARY) $(LIBRARY) $(TESTHARNESS)
	$(CXX) helpers/memenv/memenv_test.o $(MEMENVLIBRARY) $(LIBRARY) $(TESTHARNESS) -o $@ $(LDFLAGS)

ifeq ($(PLATFORM), IOS)
# For iOS, create universal object files to be used on both the simulator and
# a device.
PLATFORMSROOT=/Applications/Xcode.app/Contents/Developer/Platforms
SIMULATORROOT=$(PLATFORMSROOT)/iPhoneSimulator.platform/Developer
DEVICEROOT=$(PLATFORMSROOT)/iPhoneOS.platform/Developer
IOSVERSION=$(shell defaults read $(PLATFORMSROOT)/iPhoneOS.platform/version CFBundleShortVersionString)

.cc.o:
	mkdir -p ios-x86/$(dir $@)
	$(SIMULATORROOT)/usr/bin/$(CXX) $(CXXFLAGS) -isysroot $(SIMULATORROOT)/SDKs/iPhoneSimulator$(IOSVERSION).sdk -arch i686 -c $< -o ios-x86/$@
	mkdir -p ios-arm/$(dir $@)
	$(DEVICEROOT)/usr/bin/$(CXX) $(CXXFLAGS) -isysroot $(DEVICEROOT)/SDKs/iPhoneOS$(IOSVERSION).sdk -arch armv6 -arch armv7 -c $< -o ios-arm/$@
	lipo ios-x86/$@ ios-arm/$@ -create -output $@

.c.o:
	mkdir -p ios-x86/$(dir $@)
	$(SIMULATORROOT)/usr/bin/$(CC) $(CFLAGS) -isysroot $(SIMULATORROOT)/SDKs/iPhoneSimulator$(IOSVERSION).sdk -arch i686 -c $< -o ios-x86/$@
	mkdir -p ios-arm/$(dir $@)
	$(DEVICEROOT)/usr/bin/$(CC) $(CFLAGS) -isysroot $(DEVICEROOT)/SDKs/iPhoneOS$(IOSVERSION).sdk -arch armv6 -arch armv7 -c $< -o ios-arm/$@
	lipo ios-x86/$@ ios-arm/$@ -create -output $@

else
.cc.o:
	$(CXX) $(CXXFLAGS) -c $< -o $@

.c.o:
	$(CC) $(CFLAGS) -c $< -o $@
endif
