/*************************************************************************
 *  v      *   The Coq Proof Assistant  /  The Coq Development Team      *
 * <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016      *
 *   \VV/  ***************************************************************
 *    //   *      This file is distributed under the terms of the        *
 *         *       GNU Lesser General Public License Version 2.1         *
 *************************************************************************/

/**
 * RocksDB Native Bindings for OpenCoq AtomSpace Persistence
 * 
 * This file provides OCaml bindings to RocksDB for high-performance
 * persistent storage of the AtomSpace hypergraph.
 * 
 * Features:
 * - Key-value storage with column families
 * - Batch writes for atomic operations
 * - Snapshots for consistent reads
 * - Compression (LZ4, Snappy, Zstd)
 * - Write-ahead logging
 * - Bloom filters for fast lookups
 * 
 * Build with: -DHAVE_ROCKSDB -lrocksdb
 */

#include <caml/mlvalues.h>
#include <caml/memory.h>
#include <caml/alloc.h>
#include <caml/custom.h>
#include <caml/fail.h>
#include <caml/callback.h>

#include <stdlib.h>
#include <string.h>
#include <stdio.h>

#ifdef HAVE_ROCKSDB
#include <rocksdb/c.h>
#endif

/*
 * ============================================================================
 * Type Definitions
 * ============================================================================
 */

/* Column family names for AtomSpace storage */
#define CF_DEFAULT "default"
#define CF_NODES "nodes"
#define CF_LINKS "links"
#define CF_INCOMING "incoming"
#define CF_OUTGOING "outgoing"
#define CF_ATTENTION "attention"
#define CF_TRUTH_VALUES "truth_values"
#define CF_METADATA "metadata"

#define MAX_COLUMN_FAMILIES 16

/* Database wrapper */
typedef struct {
    void *db;                           /* rocksdb_t pointer */
    void *options;                      /* rocksdb_options_t pointer */
    void *write_options;                /* rocksdb_writeoptions_t pointer */
    void *read_options;                 /* rocksdb_readoptions_t pointer */
    void *cf_handles[MAX_COLUMN_FAMILIES];  /* Column family handles */
    int n_cf;                           /* Number of column families */
    char *path;                         /* Database path */
    int is_open;                        /* Is database open */
} rocksdb_wrapper;

/* Batch wrapper */
typedef struct {
    void *batch;                        /* rocksdb_writebatch_t pointer */
    int n_ops;                          /* Number of operations */
} rocksdb_batch_wrapper;

/* Iterator wrapper */
typedef struct {
    void *iter;                         /* rocksdb_iterator_t pointer */
    int cf_index;                       /* Column family index */
} rocksdb_iter_wrapper;

/* Snapshot wrapper */
typedef struct {
    void *snapshot;                     /* rocksdb_snapshot_t pointer */
    rocksdb_wrapper *db_wrapper;        /* Parent database */
} rocksdb_snapshot_wrapper;

/* Custom block operations */
static struct custom_operations rocksdb_ops = {
    "org.opencoq.rocksdb",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default
};

static struct custom_operations rocksdb_batch_ops = {
    "org.opencoq.rocksdb_batch",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default
};

static struct custom_operations rocksdb_iter_ops = {
    "org.opencoq.rocksdb_iter",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default
};

static struct custom_operations rocksdb_snapshot_ops = {
    "org.opencoq.rocksdb_snapshot",
    custom_finalize_default,
    custom_compare_default,
    custom_hash_default,
    custom_serialize_default,
    custom_deserialize_default,
    custom_compare_ext_default,
    custom_fixed_length_default
};

/*
 * ============================================================================
 * Helper Macros
 * ============================================================================
 */

#define Rocksdb_val(v) (*((rocksdb_wrapper **) Data_custom_val(v)))
#define Batch_val(v) (*((rocksdb_batch_wrapper **) Data_custom_val(v)))
#define Iter_val(v) (*((rocksdb_iter_wrapper **) Data_custom_val(v)))
#define Snapshot_val(v) (*((rocksdb_snapshot_wrapper **) Data_custom_val(v)))

#ifdef HAVE_ROCKSDB

/*
 * ============================================================================
 * Database Management
 * ============================================================================
 */

CAMLprim value caml_rocksdb_open(value path, value create_if_missing, value compression) {
    CAMLparam3(path, create_if_missing, compression);
    CAMLlocal1(result);
    
    char *err = NULL;
    const char *db_path = String_val(path);
    
    /* Create options */
    rocksdb_options_t *options = rocksdb_options_create();
    rocksdb_options_set_create_if_missing(options, Bool_val(create_if_missing));
    rocksdb_options_set_create_missing_column_families(options, 1);
    
    /* Set compression */
    int comp_type = Int_val(compression);
    if (comp_type == 1) {
        rocksdb_options_set_compression(options, rocksdb_snappy_compression);
    } else if (comp_type == 2) {
        rocksdb_options_set_compression(options, rocksdb_lz4_compression);
    } else if (comp_type == 3) {
        rocksdb_options_set_compression(options, rocksdb_zstd_compression);
    }
    
    /* Enable bloom filter */
    rocksdb_block_based_table_options_t *table_options = rocksdb_block_based_options_create();
    rocksdb_filterpolicy_t *bloom = rocksdb_filterpolicy_create_bloom(10);
    rocksdb_block_based_options_set_filter_policy(table_options, bloom);
    rocksdb_options_set_block_based_table_factory(options, table_options);
    
    /* Define column families */
    const char *cf_names[] = {
        CF_DEFAULT, CF_NODES, CF_LINKS, CF_INCOMING,
        CF_OUTGOING, CF_ATTENTION, CF_TRUTH_VALUES, CF_METADATA
    };
    int n_cf = 8;
    
    rocksdb_options_t *cf_options[MAX_COLUMN_FAMILIES];
    for (int i = 0; i < n_cf; i++) {
        cf_options[i] = rocksdb_options_create();
    }
    
    rocksdb_column_family_handle_t *cf_handles[MAX_COLUMN_FAMILIES];
    
    /* Open database with column families */
    rocksdb_t *db = rocksdb_open_column_families(
        options, db_path,
        n_cf, cf_names,
        (const rocksdb_options_t *const *)cf_options,
        cf_handles,
        &err
    );
    
    if (err != NULL) {
        /* Try opening without column families (new database) */
        free(err);
        err = NULL;
        
        db = rocksdb_open(options, db_path, &err);
        if (err != NULL) {
            char msg[256];
            snprintf(msg, sizeof(msg), "rocksdb_open failed: %s", err);
            free(err);
            rocksdb_options_destroy(options);
            caml_failwith(msg);
        }
        
        /* Create column families */
        for (int i = 1; i < n_cf; i++) {
            cf_handles[i] = rocksdb_create_column_family(db, options, cf_names[i], &err);
            if (err != NULL) {
                free(err);
                err = NULL;
            }
        }
        cf_handles[0] = NULL;  /* Default CF */
    }
    
    /* Create wrapper */
    rocksdb_wrapper *wrapper = (rocksdb_wrapper *)malloc(sizeof(rocksdb_wrapper));
    if (wrapper == NULL) {
        rocksdb_close(db);
        caml_failwith("rocksdb_open: failed to allocate wrapper");
    }
    
    wrapper->db = db;
    wrapper->options = options;
    wrapper->write_options = rocksdb_writeoptions_create();
    wrapper->read_options = rocksdb_readoptions_create();
    wrapper->n_cf = n_cf;
    wrapper->path = strdup(db_path);
    wrapper->is_open = 1;
    
    for (int i = 0; i < n_cf; i++) {
        wrapper->cf_handles[i] = cf_handles[i];
    }
    
    result = caml_alloc_custom(&rocksdb_ops, sizeof(rocksdb_wrapper *), 0, 1);
    Rocksdb_val(result) = wrapper;
    
    CAMLreturn(result);
}

CAMLprim value caml_rocksdb_close(value db) {
    CAMLparam1(db);
    
    rocksdb_wrapper *wrapper = Rocksdb_val(db);
    if (wrapper != NULL && wrapper->is_open) {
        /* Close column family handles */
        for (int i = 0; i < wrapper->n_cf; i++) {
            if (wrapper->cf_handles[i] != NULL) {
                rocksdb_column_family_handle_destroy(wrapper->cf_handles[i]);
            }
        }
        
        rocksdb_close(wrapper->db);
        rocksdb_options_destroy(wrapper->options);
        rocksdb_writeoptions_destroy(wrapper->write_options);
        rocksdb_readoptions_destroy(wrapper->read_options);
        
        free(wrapper->path);
        wrapper->is_open = 0;
        free(wrapper);
        Rocksdb_val(db) = NULL;
    }
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_is_open(value db) {
    CAMLparam1(db);
    
    rocksdb_wrapper *wrapper = Rocksdb_val(db);
    CAMLreturn(Val_bool(wrapper != NULL && wrapper->is_open));
}

/*
 * ============================================================================
 * Basic Operations
 * ============================================================================
 */

CAMLprim value caml_rocksdb_put(value db, value cf_index, value key, value val) {
    CAMLparam4(db, cf_index, key, val);
    
    rocksdb_wrapper *wrapper = Rocksdb_val(db);
    if (wrapper == NULL || !wrapper->is_open) {
        caml_failwith("rocksdb_put: database not open");
    }
    
    char *err = NULL;
    int cf_idx = Int_val(cf_index);
    
    if (cf_idx > 0 && cf_idx < wrapper->n_cf && wrapper->cf_handles[cf_idx] != NULL) {
        rocksdb_put_cf(
            wrapper->db,
            wrapper->write_options,
            wrapper->cf_handles[cf_idx],
            String_val(key), caml_string_length(key),
            String_val(val), caml_string_length(val),
            &err
        );
    } else {
        rocksdb_put(
            wrapper->db,
            wrapper->write_options,
            String_val(key), caml_string_length(key),
            String_val(val), caml_string_length(val),
            &err
        );
    }
    
    if (err != NULL) {
        char msg[256];
        snprintf(msg, sizeof(msg), "rocksdb_put failed: %s", err);
        free(err);
        caml_failwith(msg);
    }
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_get(value db, value cf_index, value key) {
    CAMLparam3(db, cf_index, key);
    CAMLlocal2(result, some_val);
    
    rocksdb_wrapper *wrapper = Rocksdb_val(db);
    if (wrapper == NULL || !wrapper->is_open) {
        caml_failwith("rocksdb_get: database not open");
    }
    
    char *err = NULL;
    size_t val_len;
    int cf_idx = Int_val(cf_index);
    char *val;
    
    if (cf_idx > 0 && cf_idx < wrapper->n_cf && wrapper->cf_handles[cf_idx] != NULL) {
        val = rocksdb_get_cf(
            wrapper->db,
            wrapper->read_options,
            wrapper->cf_handles[cf_idx],
            String_val(key), caml_string_length(key),
            &val_len,
            &err
        );
    } else {
        val = rocksdb_get(
            wrapper->db,
            wrapper->read_options,
            String_val(key), caml_string_length(key),
            &val_len,
            &err
        );
    }
    
    if (err != NULL) {
        char msg[256];
        snprintf(msg, sizeof(msg), "rocksdb_get failed: %s", err);
        free(err);
        caml_failwith(msg);
    }
    
    if (val == NULL) {
        /* Return None */
        result = Val_int(0);
    } else {
        /* Return Some(value) */
        some_val = caml_alloc_string(val_len);
        memcpy(Bytes_val(some_val), val, val_len);
        free(val);
        
        result = caml_alloc(1, 0);
        Store_field(result, 0, some_val);
    }
    
    CAMLreturn(result);
}

CAMLprim value caml_rocksdb_delete(value db, value cf_index, value key) {
    CAMLparam3(db, cf_index, key);
    
    rocksdb_wrapper *wrapper = Rocksdb_val(db);
    if (wrapper == NULL || !wrapper->is_open) {
        caml_failwith("rocksdb_delete: database not open");
    }
    
    char *err = NULL;
    int cf_idx = Int_val(cf_index);
    
    if (cf_idx > 0 && cf_idx < wrapper->n_cf && wrapper->cf_handles[cf_idx] != NULL) {
        rocksdb_delete_cf(
            wrapper->db,
            wrapper->write_options,
            wrapper->cf_handles[cf_idx],
            String_val(key), caml_string_length(key),
            &err
        );
    } else {
        rocksdb_delete(
            wrapper->db,
            wrapper->write_options,
            String_val(key), caml_string_length(key),
            &err
        );
    }
    
    if (err != NULL) {
        char msg[256];
        snprintf(msg, sizeof(msg), "rocksdb_delete failed: %s", err);
        free(err);
        caml_failwith(msg);
    }
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_exists(value db, value cf_index, value key) {
    CAMLparam3(db, cf_index, key);
    
    rocksdb_wrapper *wrapper = Rocksdb_val(db);
    if (wrapper == NULL || !wrapper->is_open) {
        caml_failwith("rocksdb_exists: database not open");
    }
    
    char *err = NULL;
    size_t val_len;
    int cf_idx = Int_val(cf_index);
    char *val;
    
    if (cf_idx > 0 && cf_idx < wrapper->n_cf && wrapper->cf_handles[cf_idx] != NULL) {
        val = rocksdb_get_cf(
            wrapper->db,
            wrapper->read_options,
            wrapper->cf_handles[cf_idx],
            String_val(key), caml_string_length(key),
            &val_len,
            &err
        );
    } else {
        val = rocksdb_get(
            wrapper->db,
            wrapper->read_options,
            String_val(key), caml_string_length(key),
            &val_len,
            &err
        );
    }
    
    if (err != NULL) {
        free(err);
        CAMLreturn(Val_bool(0));
    }
    
    int exists = (val != NULL);
    if (val != NULL) free(val);
    
    CAMLreturn(Val_bool(exists));
}

/*
 * ============================================================================
 * Batch Operations
 * ============================================================================
 */

CAMLprim value caml_rocksdb_batch_create(value unit) {
    CAMLparam1(unit);
    CAMLlocal1(result);
    
    rocksdb_batch_wrapper *wrapper = (rocksdb_batch_wrapper *)malloc(sizeof(rocksdb_batch_wrapper));
    if (wrapper == NULL) {
        caml_failwith("rocksdb_batch_create: failed to allocate wrapper");
    }
    
    wrapper->batch = rocksdb_writebatch_create();
    wrapper->n_ops = 0;
    
    result = caml_alloc_custom(&rocksdb_batch_ops, sizeof(rocksdb_batch_wrapper *), 0, 1);
    Batch_val(result) = wrapper;
    
    CAMLreturn(result);
}

CAMLprim value caml_rocksdb_batch_put(value batch, value key, value val) {
    CAMLparam3(batch, key, val);
    
    rocksdb_batch_wrapper *wrapper = Batch_val(batch);
    if (wrapper == NULL || wrapper->batch == NULL) {
        caml_failwith("rocksdb_batch_put: invalid batch");
    }
    
    rocksdb_writebatch_put(
        wrapper->batch,
        String_val(key), caml_string_length(key),
        String_val(val), caml_string_length(val)
    );
    wrapper->n_ops++;
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_batch_delete(value batch, value key) {
    CAMLparam2(batch, key);
    
    rocksdb_batch_wrapper *wrapper = Batch_val(batch);
    if (wrapper == NULL || wrapper->batch == NULL) {
        caml_failwith("rocksdb_batch_delete: invalid batch");
    }
    
    rocksdb_writebatch_delete(
        wrapper->batch,
        String_val(key), caml_string_length(key)
    );
    wrapper->n_ops++;
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_batch_clear(value batch) {
    CAMLparam1(batch);
    
    rocksdb_batch_wrapper *wrapper = Batch_val(batch);
    if (wrapper == NULL || wrapper->batch == NULL) {
        caml_failwith("rocksdb_batch_clear: invalid batch");
    }
    
    rocksdb_writebatch_clear(wrapper->batch);
    wrapper->n_ops = 0;
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_batch_count(value batch) {
    CAMLparam1(batch);
    
    rocksdb_batch_wrapper *wrapper = Batch_val(batch);
    if (wrapper == NULL) {
        CAMLreturn(Val_int(0));
    }
    
    CAMLreturn(Val_int(wrapper->n_ops));
}

CAMLprim value caml_rocksdb_batch_write(value db, value batch) {
    CAMLparam2(db, batch);
    
    rocksdb_wrapper *db_wrapper = Rocksdb_val(db);
    rocksdb_batch_wrapper *batch_wrapper = Batch_val(batch);
    
    if (db_wrapper == NULL || !db_wrapper->is_open) {
        caml_failwith("rocksdb_batch_write: database not open");
    }
    if (batch_wrapper == NULL || batch_wrapper->batch == NULL) {
        caml_failwith("rocksdb_batch_write: invalid batch");
    }
    
    char *err = NULL;
    rocksdb_write(db_wrapper->db, db_wrapper->write_options, batch_wrapper->batch, &err);
    
    if (err != NULL) {
        char msg[256];
        snprintf(msg, sizeof(msg), "rocksdb_batch_write failed: %s", err);
        free(err);
        caml_failwith(msg);
    }
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_batch_destroy(value batch) {
    CAMLparam1(batch);
    
    rocksdb_batch_wrapper *wrapper = Batch_val(batch);
    if (wrapper != NULL) {
        if (wrapper->batch != NULL) {
            rocksdb_writebatch_destroy(wrapper->batch);
        }
        free(wrapper);
        Batch_val(batch) = NULL;
    }
    
    CAMLreturn(Val_unit);
}

/*
 * ============================================================================
 * Iterator Operations
 * ============================================================================
 */

CAMLprim value caml_rocksdb_iter_create(value db, value cf_index) {
    CAMLparam2(db, cf_index);
    CAMLlocal1(result);
    
    rocksdb_wrapper *wrapper = Rocksdb_val(db);
    if (wrapper == NULL || !wrapper->is_open) {
        caml_failwith("rocksdb_iter_create: database not open");
    }
    
    int cf_idx = Int_val(cf_index);
    rocksdb_iterator_t *iter;
    
    if (cf_idx > 0 && cf_idx < wrapper->n_cf && wrapper->cf_handles[cf_idx] != NULL) {
        iter = rocksdb_create_iterator_cf(wrapper->db, wrapper->read_options, wrapper->cf_handles[cf_idx]);
    } else {
        iter = rocksdb_create_iterator(wrapper->db, wrapper->read_options);
    }
    
    rocksdb_iter_wrapper *iter_wrapper = (rocksdb_iter_wrapper *)malloc(sizeof(rocksdb_iter_wrapper));
    if (iter_wrapper == NULL) {
        rocksdb_iter_destroy(iter);
        caml_failwith("rocksdb_iter_create: failed to allocate wrapper");
    }
    
    iter_wrapper->iter = iter;
    iter_wrapper->cf_index = cf_idx;
    
    result = caml_alloc_custom(&rocksdb_iter_ops, sizeof(rocksdb_iter_wrapper *), 0, 1);
    Iter_val(result) = iter_wrapper;
    
    CAMLreturn(result);
}

CAMLprim value caml_rocksdb_iter_seek_to_first(value iter) {
    CAMLparam1(iter);
    
    rocksdb_iter_wrapper *wrapper = Iter_val(iter);
    if (wrapper == NULL || wrapper->iter == NULL) {
        caml_failwith("rocksdb_iter_seek_to_first: invalid iterator");
    }
    
    rocksdb_iter_seek_to_first(wrapper->iter);
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_seek_to_last(value iter) {
    CAMLparam1(iter);
    
    rocksdb_iter_wrapper *wrapper = Iter_val(iter);
    if (wrapper == NULL || wrapper->iter == NULL) {
        caml_failwith("rocksdb_iter_seek_to_last: invalid iterator");
    }
    
    rocksdb_iter_seek_to_last(wrapper->iter);
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_seek(value iter, value key) {
    CAMLparam2(iter, key);
    
    rocksdb_iter_wrapper *wrapper = Iter_val(iter);
    if (wrapper == NULL || wrapper->iter == NULL) {
        caml_failwith("rocksdb_iter_seek: invalid iterator");
    }
    
    rocksdb_iter_seek(wrapper->iter, String_val(key), caml_string_length(key));
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_next(value iter) {
    CAMLparam1(iter);
    
    rocksdb_iter_wrapper *wrapper = Iter_val(iter);
    if (wrapper == NULL || wrapper->iter == NULL) {
        caml_failwith("rocksdb_iter_next: invalid iterator");
    }
    
    rocksdb_iter_next(wrapper->iter);
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_prev(value iter) {
    CAMLparam1(iter);
    
    rocksdb_iter_wrapper *wrapper = Iter_val(iter);
    if (wrapper == NULL || wrapper->iter == NULL) {
        caml_failwith("rocksdb_iter_prev: invalid iterator");
    }
    
    rocksdb_iter_prev(wrapper->iter);
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_valid(value iter) {
    CAMLparam1(iter);
    
    rocksdb_iter_wrapper *wrapper = Iter_val(iter);
    if (wrapper == NULL || wrapper->iter == NULL) {
        CAMLreturn(Val_bool(0));
    }
    
    CAMLreturn(Val_bool(rocksdb_iter_valid(wrapper->iter)));
}

CAMLprim value caml_rocksdb_iter_key(value iter) {
    CAMLparam1(iter);
    CAMLlocal1(result);
    
    rocksdb_iter_wrapper *wrapper = Iter_val(iter);
    if (wrapper == NULL || wrapper->iter == NULL) {
        caml_failwith("rocksdb_iter_key: invalid iterator");
    }
    
    size_t key_len;
    const char *key = rocksdb_iter_key(wrapper->iter, &key_len);
    
    result = caml_alloc_string(key_len);
    memcpy(Bytes_val(result), key, key_len);
    
    CAMLreturn(result);
}

CAMLprim value caml_rocksdb_iter_value(value iter) {
    CAMLparam1(iter);
    CAMLlocal1(result);
    
    rocksdb_iter_wrapper *wrapper = Iter_val(iter);
    if (wrapper == NULL || wrapper->iter == NULL) {
        caml_failwith("rocksdb_iter_value: invalid iterator");
    }
    
    size_t val_len;
    const char *val = rocksdb_iter_value(wrapper->iter, &val_len);
    
    result = caml_alloc_string(val_len);
    memcpy(Bytes_val(result), val, val_len);
    
    CAMLreturn(result);
}

CAMLprim value caml_rocksdb_iter_destroy(value iter) {
    CAMLparam1(iter);
    
    rocksdb_iter_wrapper *wrapper = Iter_val(iter);
    if (wrapper != NULL) {
        if (wrapper->iter != NULL) {
            rocksdb_iter_destroy(wrapper->iter);
        }
        free(wrapper);
        Iter_val(iter) = NULL;
    }
    
    CAMLreturn(Val_unit);
}

/*
 * ============================================================================
 * Snapshot Operations
 * ============================================================================
 */

CAMLprim value caml_rocksdb_snapshot_create(value db) {
    CAMLparam1(db);
    CAMLlocal1(result);
    
    rocksdb_wrapper *wrapper = Rocksdb_val(db);
    if (wrapper == NULL || !wrapper->is_open) {
        caml_failwith("rocksdb_snapshot_create: database not open");
    }
    
    const rocksdb_snapshot_t *snapshot = rocksdb_create_snapshot(wrapper->db);
    
    rocksdb_snapshot_wrapper *snap_wrapper = (rocksdb_snapshot_wrapper *)malloc(sizeof(rocksdb_snapshot_wrapper));
    if (snap_wrapper == NULL) {
        rocksdb_release_snapshot(wrapper->db, snapshot);
        caml_failwith("rocksdb_snapshot_create: failed to allocate wrapper");
    }
    
    snap_wrapper->snapshot = (void *)snapshot;
    snap_wrapper->db_wrapper = wrapper;
    
    result = caml_alloc_custom(&rocksdb_snapshot_ops, sizeof(rocksdb_snapshot_wrapper *), 0, 1);
    Snapshot_val(result) = snap_wrapper;
    
    CAMLreturn(result);
}

CAMLprim value caml_rocksdb_snapshot_release(value snapshot) {
    CAMLparam1(snapshot);
    
    rocksdb_snapshot_wrapper *wrapper = Snapshot_val(snapshot);
    if (wrapper != NULL && wrapper->snapshot != NULL && wrapper->db_wrapper != NULL) {
        rocksdb_release_snapshot(wrapper->db_wrapper->db, wrapper->snapshot);
        wrapper->snapshot = NULL;
        free(wrapper);
        Snapshot_val(snapshot) = NULL;
    }
    
    CAMLreturn(Val_unit);
}

/*
 * ============================================================================
 * Statistics and Utilities
 * ============================================================================
 */

CAMLprim value caml_rocksdb_get_property(value db, value property) {
    CAMLparam2(db, property);
    CAMLlocal2(result, some_val);
    
    rocksdb_wrapper *wrapper = Rocksdb_val(db);
    if (wrapper == NULL || !wrapper->is_open) {
        caml_failwith("rocksdb_get_property: database not open");
    }
    
    char *val = rocksdb_property_value(wrapper->db, String_val(property));
    
    if (val == NULL) {
        result = Val_int(0);  /* None */
    } else {
        some_val = caml_copy_string(val);
        free(val);
        
        result = caml_alloc(1, 0);
        Store_field(result, 0, some_val);
    }
    
    CAMLreturn(result);
}

CAMLprim value caml_rocksdb_compact_range(value db, value cf_index) {
    CAMLparam2(db, cf_index);
    
    rocksdb_wrapper *wrapper = Rocksdb_val(db);
    if (wrapper == NULL || !wrapper->is_open) {
        caml_failwith("rocksdb_compact_range: database not open");
    }
    
    int cf_idx = Int_val(cf_index);
    
    if (cf_idx > 0 && cf_idx < wrapper->n_cf && wrapper->cf_handles[cf_idx] != NULL) {
        rocksdb_compact_range_cf(wrapper->db, wrapper->cf_handles[cf_idx], NULL, 0, NULL, 0);
    } else {
        rocksdb_compact_range(wrapper->db, NULL, 0, NULL, 0);
    }
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_flush(value db) {
    CAMLparam1(db);
    
    rocksdb_wrapper *wrapper = Rocksdb_val(db);
    if (wrapper == NULL || !wrapper->is_open) {
        caml_failwith("rocksdb_flush: database not open");
    }
    
    char *err = NULL;
    rocksdb_flushoptions_t *flush_options = rocksdb_flushoptions_create();
    rocksdb_flushoptions_set_wait(flush_options, 1);
    
    rocksdb_flush(wrapper->db, flush_options, &err);
    rocksdb_flushoptions_destroy(flush_options);
    
    if (err != NULL) {
        char msg[256];
        snprintf(msg, sizeof(msg), "rocksdb_flush failed: %s", err);
        free(err);
        caml_failwith(msg);
    }
    
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_backend_available(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(1));
}

#else /* !HAVE_ROCKSDB */

/*
 * ============================================================================
 * Stub Implementations
 * ============================================================================
 */

static void rocksdb_not_available(void) {
    caml_failwith("RocksDB native bindings not available. Compile with -DHAVE_ROCKSDB and link with -lrocksdb");
}

CAMLprim value caml_rocksdb_open(value path, value create_if_missing, value compression) {
    CAMLparam3(path, create_if_missing, compression);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_close(value db) {
    CAMLparam1(db);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_is_open(value db) {
    CAMLparam1(db);
    CAMLreturn(Val_bool(0));
}

CAMLprim value caml_rocksdb_put(value db, value cf_index, value key, value val) {
    CAMLparam4(db, cf_index, key, val);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_get(value db, value cf_index, value key) {
    CAMLparam3(db, cf_index, key);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_delete(value db, value cf_index, value key) {
    CAMLparam3(db, cf_index, key);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_exists(value db, value cf_index, value key) {
    CAMLparam3(db, cf_index, key);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_batch_create(value unit) {
    CAMLparam1(unit);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_batch_put(value batch, value key, value val) {
    CAMLparam3(batch, key, val);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_batch_delete(value batch, value key) {
    CAMLparam2(batch, key);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_batch_clear(value batch) {
    CAMLparam1(batch);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_batch_count(value batch) {
    CAMLparam1(batch);
    CAMLreturn(Val_int(0));
}

CAMLprim value caml_rocksdb_batch_write(value db, value batch) {
    CAMLparam2(db, batch);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_batch_destroy(value batch) {
    CAMLparam1(batch);
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_create(value db, value cf_index) {
    CAMLparam2(db, cf_index);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_seek_to_first(value iter) {
    CAMLparam1(iter);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_seek_to_last(value iter) {
    CAMLparam1(iter);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_seek(value iter, value key) {
    CAMLparam2(iter, key);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_next(value iter) {
    CAMLparam1(iter);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_prev(value iter) {
    CAMLparam1(iter);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_valid(value iter) {
    CAMLparam1(iter);
    CAMLreturn(Val_bool(0));
}

CAMLprim value caml_rocksdb_iter_key(value iter) {
    CAMLparam1(iter);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_value(value iter) {
    CAMLparam1(iter);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_iter_destroy(value iter) {
    CAMLparam1(iter);
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_snapshot_create(value db) {
    CAMLparam1(db);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_snapshot_release(value snapshot) {
    CAMLparam1(snapshot);
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_get_property(value db, value property) {
    CAMLparam2(db, property);
    CAMLreturn(Val_int(0));  /* None */
}

CAMLprim value caml_rocksdb_compact_range(value db, value cf_index) {
    CAMLparam2(db, cf_index);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_flush(value db) {
    CAMLparam1(db);
    rocksdb_not_available();
    CAMLreturn(Val_unit);
}

CAMLprim value caml_rocksdb_backend_available(value unit) {
    CAMLparam1(unit);
    CAMLreturn(Val_bool(0));
}

#endif /* HAVE_ROCKSDB */
