#movies
./test_movies_rocksdb.sh > /home/panfengfeng/result/on-disk/movies/readrandom_multi_rocksdb_256_128m_mem2g

./test_movies_wiredtiger_over.sh > /home/panfengfeng/result/on-disk/movies/readrandom_multi_wiredtiger_no_lsm_128m_over_mem2g

./test_movies_terark_index.sh > /home/panfengfeng/result/on-disk/movies/readrandom_multi_terark_index_100_mem2g_16g_1g

./test_movies_leveldb.sh > /home/panfengfeng/result/on-disk/movies/readrandom_multi_leveldb_256_128m_mem2g
