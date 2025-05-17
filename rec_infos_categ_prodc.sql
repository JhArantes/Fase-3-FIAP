SELECT 
    cat.cd_categoria,
    cat.ds_categoria,
    NVL(COUNT(sac.nr_sac), 0) AS total_chamados
FROM 
    mc_categoria_prod cat
LEFT JOIN 
    mc_produto prod ON prod.cd_categoria = cat.cd_categoria
LEFT JOIN 
    mc_sgv_sac sac ON sac.cd_produto = prod.cd_produto
GROUP BY 
    cat.cd_categoria, cat.ds_categoria
ORDER BY 
    cat.cd_categoria;