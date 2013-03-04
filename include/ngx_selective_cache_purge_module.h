#ifndef _NGX_SELECTIVE_CACHE_PURGE_MODULE_H_
#define _NGX_SELECTIVE_CACHE_PURGE_MODULE_H_

#include <sqlite3.h>
#include <ngx_config.h>
#include <ngx_core.h>
#include <ngx_http.h>

typedef struct {
    ngx_flag_t                enabled;
    ngx_str_t                 database_filename;
    sqlite3                  *db;
} ngx_selective_cache_purge_main_conf_t;

typedef struct {
    ngx_http_complex_value_t *purge_query;
} ngx_selective_cache_purge_loc_conf_t;

static ngx_selective_cache_purge_main_conf_t *ngx_selective_cache_purge_module_main_conf;

static ngx_int_t ngx_selective_cache_purge_filter(ngx_http_request_t *r);
static ngx_int_t ngx_selective_cache_purge_handler(ngx_http_request_t *r);

#endif /* _NGX_SELECTIVE_CACHE_PURGE_MODULE_H_ */
