#include "gmperl_nifs.h"
{% for f in mpz %}{% include "priv/templates/fun.c" %}{% endfor %}

GMPERL_NIF_PROTOTYPE(gmperl_mpz_refeq)
{
    ERL_NIF_TERM ret;
    gmperl_privdata_t *priv = enif_priv_data(env);
    gmperl_mpz_t *val1, *val2;

    if (!enif_get_resource(env, argv[0], priv->gmperl_mpz_rt, (void**)&val1)) {
        goto badarg;
    }
    if (!enif_get_resource(env, argv[1], priv->gmperl_mpz_rt, (void**)&val2)) {
        goto badarg;
    }

    int val0 = val1->z == val2->z;
    ret = enif_get_boolean(env, val0);
    return ret;

 badarg:
    return enif_make_badarg(env);
}

GMPERL_NIF_PROTOTYPE(gmperl_mpz_import)
{
    ERL_NIF_TERM ret;
    gmperl_privdata_t *priv = enif_priv_data(env);
    gmperl_mpz_t *rop;
    unsigned long count, size, nails;
    int order, endian;
    ErlNifBinary op;

    if (!enif_get_resource(env, argv[0], priv->gmperl_mpz_rt, (void**)&rop)) {
	goto badarg;
    }
    if (!enif_get_ulong     (env, argv[1], &count))  goto badarg;
    if (!enif_get_int       (env, argv[2], &order))  goto badarg;
    if (!enif_get_ulong     (env, argv[3], &size))   goto badarg;
    if (!enif_get_int       (env, argv[4], &endian)) goto badarg;
    if (!enif_get_ulong     (env, argv[5], &nails))  goto badarg;
    if (!enif_inspect_binary(env, argv[6], &op))     goto badarg;

    if (count > op.size / size) goto badarg; /* too few bytes in op */
    if (order != 1 && order != -1) goto badarg;
    if (size == 0) goto badarg; /* 0 byte words makes no sense */
    if (endian != 1 && endian != 0 && endian != -1) goto badarg;
    if (nails / 8 >= size) goto badarg; /* more nail bits than bits per word */

    mpz_import(rop->z, count, order, size, endian, nails, op.data);

    ret = enif_get_ok(env);
    return ret;

 badarg:
    return enif_make_badarg(env);
}

GMPERL_NIF_PROTOTYPE(gmperl_mpz_export)
{
    ERL_NIF_TERM ret;
    gmperl_privdata_t *priv = enif_priv_data(env);
    gmperl_mpz_t *op;
    unsigned long size, nails;
    int order, endian;
    ErlNifBinary rop;

    if (!enif_get_int  (env, argv[0], &order))  goto badarg;
    if (!enif_get_ulong(env, argv[1], &size))   goto badarg;
    if (!enif_get_int  (env, argv[2], &endian)) goto badarg;
    if (!enif_get_ulong(env, argv[3], &nails))  goto badarg;
    if (!enif_get_resource(env, argv[4], priv->gmperl_mpz_rt, (void**)&op)) {
	goto badarg;
    }

    if (order != 1 && order != -1) goto badarg;
    if (size == 0) goto badarg; /* 0 byte words makes no sense */
    if (endian != 1 && endian != 0 && endian != -1) goto badarg;
    if (nails / 8 >= size) goto badarg; /* more nail bits than bits per word */

    size_t bits_per_word = 8 * size - nails;
    size_t expected_words = (mpz_sizeinbase(op->z, 2) + bits_per_word - 1)
	/ bits_per_word;

    if (!enif_alloc_binary(expected_words * size, &rop)) goto alloc_failed;

    size_t actual_words;
    mpz_export(rop.data, &actual_words, order, size, endian, nails, op->z);

    if (actual_words != expected_words) {
	/* ASSERT(actual_words < expected_words); */
	if (!enif_realloc_binary(&rop, actual_words * size)) {
	    enif_release_binary(&rop);
	    goto alloc_failed;
	}
    }

    ret = enif_make_binary(env, &rop);
    return ret;

 alloc_failed:
    return enif_raise_exception(env, enif_make_atom(env, "alloc_failed"));

 badarg:
    return enif_make_badarg(env);
}
