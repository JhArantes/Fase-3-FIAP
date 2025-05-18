DECLARE
    -- Cursor com todos os dados necessários
    CURSOR cur_sac IS
        SELECT 
            sac.nr_sac,
            sac.dt_abertura_sac,
            sac.hr_abertura_sac,
            sac.tp_sac,
            prod.cd_produto,
            prod.ds_produto,
            prod.vl_unitario,
            prod.vl_perc_lucro,
            cli.nr_cliente,
            cli.nm_cliente,
            est.sg_estado,
            est.nm_estado
        FROM mc_sgv_sac sac
        JOIN mc_produto prod ON sac.cd_produto = prod.cd_produto
        JOIN mc_cliente cli ON sac.nr_cliente = cli.nr_cliente
        JOIN mc_end_cli endc ON cli.nr_cliente = endc.nr_cliente
        JOIN mc_logradouro log ON endc.cd_logradouro_cli = log.cd_logradouro
        JOIN mc_bairro bai ON log.cd_bairro = bai.cd_bairro
        JOIN mc_cidade cid ON bai.cd_cidade = cid.cd_cidade
        JOIN mc_estado est ON cid.sg_estado = est.sg_estado;

    -- Variáveis para armazenar os dados do cursor
    v_nr_sac               mc_sgv_sac.nr_sac%TYPE;
    v_dt_abertura_sac      mc_sgv_sac.dt_abertura_sac%TYPE;
    v_hr_abertura_sac      mc_sgv_sac.hr_abertura_sac%TYPE;
    v_tp_sac               mc_sgv_sac.tp_sac%TYPE;
    v_cd_produto           mc_produto.cd_produto%TYPE;
    v_ds_produto           mc_produto.ds_produto%TYPE;
    v_vl_unitario          mc_produto.vl_unitario%TYPE;
    v_vl_perc_lucro        mc_produto.vl_perc_lucro%TYPE;
    v_nr_cliente           mc_cliente.nr_cliente%TYPE;
    v_nm_cliente           mc_cliente.nm_cliente%TYPE;
    v_sg_estado            mc_estado.sg_estado%TYPE;
    v_nm_estado            mc_estado.nm_estado%TYPE;

    -- Variáveis calculadas
    v_ds_tipo_classificacao_sac VARCHAR2(50);
    v_vl_unitario_lucro_produto NUMBER;
    v_vl_icms_produto           NUMBER := NULL;

BEGIN
    FOR rec IN cur_sac LOOP
        -- Atribuir variáveis
        v_nr_sac           := rec.nr_sac;
        v_dt_abertura_sac  := rec.dt_abertura_sac;
        v_hr_abertura_sac  := rec.hr_abertura_sac;
        v_tp_sac           := rec.tp_sac;
        v_cd_produto       := rec.cd_produto;
        v_ds_produto       := rec.ds_produto;
        v_vl_unitario      := rec.vl_unitario;
        v_vl_perc_lucro    := rec.vl_perc_lucro;
        v_nr_cliente       := rec.nr_cliente;
        v_nm_cliente       := rec.nm_cliente;
        v_sg_estado        := rec.sg_estado;
        v_nm_estado        := rec.nm_estado;

        -- Regra de classificação
        CASE v_tp_sac
            WHEN 'S' THEN v_ds_tipo_classificacao_sac := 'SUGESTÃO';
            WHEN 'D' THEN v_ds_tipo_classificacao_sac := 'DÚVIDA';
            WHEN 'E' THEN v_ds_tipo_classificacao_sac := 'ELOGIO';
            ELSE v_ds_tipo_classificacao_sac := 'CLASSIFICAÇÃO INVÁLIDA';
        END CASE;

        -- Cálculo do lucro unitário
        v_vl_unitario_lucro_produto := (v_vl_perc_lucro / 100) * v_vl_unitario;

        -- Cálculo do ICMS baseado no estado
        IF v_sg_estado IN ('SP', 'RJ', 'MG', 'ES') THEN
            v_vl_icms_produto := v_vl_unitario * 0.18; -- 18% para estados do Sudeste
        ELSIF v_sg_estado IN ('RS', 'SC', 'PR') THEN
            v_vl_icms_produto := v_vl_unitario * 0.17; -- 17% para estados do Sul
        ELSE
            v_vl_icms_produto := v_vl_unitario * 0.12; -- 12% para outros estados
        END IF;

        -- Inserção dos dados processados
        INSERT INTO MC_SGV_OCORRENCIA_SAC (
            nr_ocorrencia_sac,
            dt_abertura_sac,
            hr_abertura_sac,
            ds_tipo_classificacao_sac,
            cd_produto,
            ds_produto,
            vl_unitario_produto,
            vl_perc_lucro,
            vl_unitario_lucro_produto,
            sg_estado,
            nm_estado,
            nr_cliente,
            nm_cliente,
            vl_icms_produto
        ) VALUES (
            v_nr_sac,
            v_dt_abertura_sac,
            v_hr_abertura_sac,
            v_ds_tipo_classificacao_sac,
            v_cd_produto,
            v_ds_produto,
            v_vl_unitario,
            v_vl_perc_lucro,
            v_vl_unitario_lucro_produto,
            v_sg_estado,
            v_nm_estado,
            v_nr_cliente,
            v_nm_cliente,
            v_vl_icms_produto
        );
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Processamento concluído com sucesso! Registros processados: ' || cur_sac%ROWCOUNT);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Erro: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Erro na linha: ' || DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
        ROLLBACK;
END;



SELECT *
FROM MC_SGV_OCORRENCIA_SAC;