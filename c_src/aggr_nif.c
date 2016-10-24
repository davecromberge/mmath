#include "erl_nif.h"
#include "mmath.h"

#include <math.h>

typedef ffloat (*aggr_func) (ffloat, ffloat);
typedef ffloat (*emit_func) (ffloat, double);

static int
load(ErlNifEnv* env, void** priv, ERL_NIF_TERM load_info)
{
  return 0;
}

static int
upgrade(ErlNifEnv* env, void** priv, void** old_priv, ERL_NIF_TERM load_info)
{
  return 0;
}

static ERL_NIF_TERM
aggr2(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[], aggr_func f, emit_func g)
{
  ErlNifBinary bin;
  ErlNifSInt64 chunk;         // size to be compressed

  ERL_NIF_TERM r;
  ffloat* vs;
  ffloat* target;
  ffloat aggr;          // Aggregator
  double confidence;

  uint32_t target_i = 0;      // target position
  uint32_t count;
  uint32_t pos = 0;
  uint32_t target_size;

  if (argc != 2)
    return enif_make_badarg(env);

  GET_CHUNK(chunk);
  GET_BIN(0, bin, count, vs);

  target_size = ceil((double) count / chunk) * sizeof(ffloat);
  if (! (target = (ffloat*) enif_make_new_binary(env, target_size, &r)))
    return enif_make_badarg(env); // TODO return propper error
  if (count > 0) {
    aggr = vs[0];
    confidence = aggr.confidence;
    pos = 1;
    //We will be overwriting the confidence generated by dec_add because
    //it would give a false impression based on the later values having
    //a higher influence.
    for (uint32_t i = 1; i < count; i++, pos++) {
      if (pos == chunk) {
        aggr.confidence = confidence / chunk;
        target[target_i] = g(aggr, chunk);
        target_i++;
        aggr = vs[i];
        confidence = aggr.confidence;
        pos = 0;
      } else {
        confidence += vs[i].confidence;
        aggr = f(aggr, vs[i]);
      }
    }

    if (count % chunk) {
      for (uint32_t i = 0; i < (chunk - (count % chunk)); i++) {
          aggr = f(aggr, vs[count-1]);
      }
    }

    aggr.confidence = confidence / chunk;
    target[target_i] = g(aggr, chunk);
  }

  return r;
}

static ERL_NIF_TERM
aggr(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[], aggr_func f)
{
    return aggr2(env, argc, argv, f, float_const);
}

static ERL_NIF_TERM
min(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  return aggr(env, argc, argv, float_min);
}

static ERL_NIF_TERM
max(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  return aggr(env, argc, argv, float_max);
}

static ERL_NIF_TERM
sum(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  return aggr(env, argc, argv, float_add);
}

static ERL_NIF_TERM
avg(ErlNifEnv* env, int argc, const ERL_NIF_TERM argv[])
{
  return aggr2(env, argc, argv, float_add, float_divc);
}

static ErlNifFunc nif_funcs[] = {
  {"min",        2, min},
  {"max",        2, max},
  {"sum",        2, sum},
  {"avg",        2, avg}
};

// Initialize this NIF library.
//
// Args: (MODULE, ErlNifFunc funcs[], load, reload, upgrade, unload)
// Docs: http://erlang.org/doc/man/erl_nif.html#ERL_NIF_INIT

ERL_NIF_INIT(mmath_aggr, nif_funcs, &load, NULL, &upgrade, NULL);
