SELECT t0.*, t1.AcctName FROM ( 
-- 1 - PAGAMENTOS CONTA
SELECT 
		t1.DocNum,
		t0.LineId,
		t1.DocType, 
		t1.DocDate,
		NULL AS CardCode,
		NULL AS CardName,
		t1.DocTotal,
		t1.TransId AS DocTransId,
		CASE
			WHEN t1.CashSum  > 0 THEN t1.CashAcct
			WHEN t1.CheckSum > 0 THEN '1.01.01.03.01'
			WHEN t1.TrsfrSum > 0 THEN t1.TrsfrAcct
			ELSE NULL
			END AS PayAcct,
		t0.AcctCode,
		-t0.SumApplied AS SumApplied,
		t0.OcrCode

    FROM	VPM4 t0
		INNER JOIN OVPM t1 ON t1.DocNum	  = t0.DocNum --Join cabeçalho

    WHERE 
			t1.Canceled = 'N'  -- Verifica se o documento foi cancelado
		AND t1.CashSum + t1.CheckSum + t1.TrsfrSum > 0 -- Verifica se a baixa de compensação (sem financeiro)
		AND t1.DocType  = 'A' -- Verifica se o documento é orinada de conta ou fonrcedor / cliente
		AND LEFT(t0.AcctCode,7)<>'1.01.01' --Filtrar transferências entre contas da empresa

UNION ALL
-- 2 - PAGAMENTOS FORNECEDORES
SELECT 
		t1.DocNum,
		t0.InvoiceId AS LineId,
		t1.DocType,
		t1.DocDate,
		t1.CardCode,
		t1.CardName,
		t1.DocTotal,
		t0.DocTransId,
		CASE
			WHEN t1.CashSum  > 0 THEN t1.CashAcct
			WHEN t1.CheckSum > 0 THEN '1.01.01.03.01'
			WHEN t1.TrsfrSum > 0 THEN t1.TrsfrAcct
			ELSE NULL
			END AS PayAcct,
		t3.Account AS AccountCode,
		(
			(t3.Debit - t3.Credit) --Saldo valor da linha da conta contábil
			/  (SELECT SUM(Debit) - SUM(Credit) --Dividido pelo saldo de todo lançamento contábil
					FROM JDT1 
					WHERE TransId = t0.DocTransId 
							AND Account <> '2.01.01.01.01'
				)
		) 
				* - t0.SumApplied  --Multiplicado pelo valor da baixa 
				AS SumApplied,
		t3.OcrCode

	FROM	VPM2 t0
		INNER JOIN OVPM t1 ON t1.DocNum	  = t0.DocNum		--Join cabeçalho pagamentos
		LEFT JOIN  OJDT t2 ON t2.TransId  = t0.DocTransId	--Join cabeçalho lançamentos ctbeis
		LEFT JOIN (SELECT TransId, Account, ProfitCode AS OcrCode, Debit, Credit -- Join cabeçalho lançamentos ctbeis
					FROM JDT1 WHERE Account <> '2.01.01.01.01') t3 ON t3.TransId = t2.TransId   --Filtrar créditos dos forncedores

	WHERE		t1.Canceled = 'N' -- Verifica se o documento foi cancelado
		AND t1.CashSum + t1.CheckSum + t1.TrsfrSum > 0 -- Verifica se a baixa de compensação (sem financeiro)
		AND t1.DocType <> 'A' -- Verifica se o documento é orinada de conta ou fonrcedor / cliente

UNION ALL
-- 3 - RECEBIMENTOS CONTA
SELECT 
		t1.DocNum,
		t0.LineId,
		t1.DocType, 
		t1.DocDate,
		NULL AS CardCode,
		NULL AS CardName,
		t1.DocTotal,
		t1.TransId AS DocTransId,
		CASE
			WHEN t1.CashSum  > 0 THEN t1.CashAcct
			WHEN t1.CheckSum > 0 THEN '1.01.01.03.01'
			WHEN t1.TrsfrSum > 0 THEN t1.TrsfrAcct
			ELSE NULL
			END AS PayAcct,
		t0.AcctCode,
		t0.SumApplied,
		t0.OcrCode

	FROM	RCT4 t0
		INNER JOIN ORCT t1 ON t1.DocNum	  = t0.DocNum	--Join cabeçalho recebimentos

	WHERE 
			t1.Canceled = 'N' -- Verifica se o documento foi cancelado
		AND t1.CashSum + t1.CheckSum + t1.TrsfrSum > 0 -- Verifica se a baixa de compensação (sem financeiro)
		AND t1.DocType  = 'A' -- Verifica se o documento é orinada de conta ou fonrcedor / cliente
		AND LEFT(t0.AcctCode,7) <> '1.01.01' -- Excluir transferências entre contas da empresa
		AND LEFT(t0.AcctCode,10) <> '1.01.03.07' -- Exclui transferências de valores do acerto dos vendedores

UNION ALL
-- 4 - RECEBIMENTOS INVERTIDO DE DEVOLUCOES DE VENDAS
SELECT 
		t1.DocNum,
		t0.InvoiceId AS LineId,
		t1.DocType,
		t1.DocDate,
		t1.CardCode,
		t1.CardName,
		t1.DocTotal,
		t0.DocTransId,
		CASE
			WHEN t1.CashSum  > 0 THEN t1.CashAcct
			WHEN t1.CheckSum > 0 THEN '1.01.01.03.01'
			WHEN t1.TrsfrSum > 0 THEN t1.TrsfrAcct
			ELSE NULL
			END AS PayAcct,
		t3.AccountCode AS AcctCode,
		(
			(t3.LineTotal --Valor do item
			/ (SELECT SUM(LineTotal)  --Valor total da NFE
				FROM INV1 
				WHERE DocEntry = t0.DocEntry)
			) * - t0.SumApplied --Multiplicacao pelo valor da baixa (recebimento)
		)	AS SumApplied,
		t3.OcrCode

	FROM	RCT2 t0
		INNER JOIN ORCT t1 ON t1.DocNum	  = t0.DocNum		--Join cabeçalho pagamentos
		LEFT JOIN (SELECT DocEntry, AcctCode AS AccountCode, LineTotal, OcrCode FROM INV1 ) t3 ON t3.DocEntry = t0.DocEntry --Join linha nota fiscal
        LEFT JOIN (SELECT OINV.DocEntry, MAX(distribuidor.Distribuidor) AS Distribuidor FROM OINV
                    INNER JOIN (SELECT DocEntry, IIF(Usage=16,1,0) AS Distribuidor 
								FROM INV1) distribuidor ON distribuidor.DocEntry = OINV.DocEntry
                    			GROUP BY OINV.DocEntry) t4 ON t4.DocEntry = t0.DocEntry
		
	WHERE		t1.Canceled = 'N' -- Verifica se o documento foi cancelado
		AND t1.CashSum + t1.CheckSum + t1.TrsfrSum > 0 -- Verifica se a baixa de compensação (sem financeiro)
		AND t1.DocType <> 'A' -- Verifica se o documento é orinada de conta ou fonrcedor / cliente
        AND t4.Distribuidor <> 1 -- Verifica se é uma venda feita pelo distribuidor para desconsiderar
		AND t0.InvType = 14 -- Verifica se o documento é de nota fiscal ou devolucao de nota fiscal

UNION ALL
-- 5 - RECEBIMENTOS DE NOTAS FISCAIS
SELECT 
		t1.DocNum,
		t0.InvoiceId AS LineId,
		t1.DocType,
		t1.DocDate,
		t1.CardCode,
		t1.CardName,
		t1.DocTotal,
		t0.DocTransId,
		CASE
			WHEN t1.CashSum  > 0 THEN t1.CashAcct
			WHEN t1.CheckSum > 0 THEN '1.01.01.03.01'
			WHEN t1.TrsfrSum > 0 THEN t1.TrsfrAcct
			ELSE NULL
			END AS PayAcct,
		t3.AccountCode AS AcctCode,
		(
			(t3.LineTotal --Valor do item
			/ (SELECT SUM(LineTotal)  --Valor total da NFE
				FROM INV1 
				WHERE DocEntry = t0.DocEntry)
			) * t0.SumApplied --Multiplicacao pelo valor da baixa (recebimento)
		)		AS SumApplied,
		t3.OcrCode

	FROM	RCT2 t0
		INNER JOIN ORCT t1 ON t1.DocNum	  = t0.DocNum		--Join cabeçalho pagamentos
		LEFT JOIN (SELECT DocEntry, AcctCode AS AccountCode, LineTotal, OcrCode FROM INV1 ) t3 ON t3.DocEntry = t0.DocEntry --Join linha nota fiscal
        LEFT JOIN (SELECT OINV.DocEntry, MAX(distribuidor.Distribuidor) AS Distribuidor FROM OINV
                    INNER JOIN (SELECT DocEntry, IIF(Usage=16,1,0) AS Distribuidor 
								FROM INV1) distribuidor ON distribuidor.DocEntry = OINV.DocEntry
                    			GROUP BY OINV.DocEntry) t4 ON t4.DocEntry = t0.DocEntry
		
	WHERE		t1.Canceled = 'N' -- Verifica se o documento foi cancelado
		AND t1.CashSum + t1.CheckSum + t1.TrsfrSum > 0 -- Verifica se a baixa de compensação (sem financeiro)
		AND t1.DocType <> 'A' -- Verifica se o documento é orinada de conta ou fonrcedor / cliente
        AND t4.Distribuidor <> 1 -- Verifica se é uma venda feita pelo distribuidor para desconsiderar
		AND t0.InvType = 13 -- Verifica se o documento é de nota fiscal

UNION ALL
-- 6 - RECEBIMENTOS SEM SER NOTA FISCAL
SELECT 
		t1.DocNum,
		t0.InvoiceId AS LineId,
		t1.DocType,
		t1.DocDate,
		t1.CardCode,
		t1.CardName,
		t1.DocTotal,
		t0.DocTransId,
		CASE
			WHEN t1.CashSum  > 0 THEN t1.CashAcct
			WHEN t1.CheckSum > 0 THEN '1.01.01.03.01'
			WHEN t1.TrsfrSum > 0 THEN t1.TrsfrAcct
			ELSE NULL
			END AS PayAcct,
		t3.Account AS AcctCode,
		(
			(t3.Debit - t3.Credit) --Saldo valor da linha da conta contábil
			/  (SELECT SUM(Debit) - SUM(Credit) --Dividido pelo saldo de todo lançamento contábil
					FROM JDT1 
					WHERE TransId = t0.DocTransId 
							AND Account <> '1.01.03.01.01'
				)
		) 
				* t0.SumApplied  --Multiplicado pelo valor da baixa 
				AS SumApplied,
		t3.OcrCode

	FROM	RCT2 t0
		INNER JOIN ORCT t1 ON t1.DocNum	  = t0.DocNum		--Join cabeçalho pagamentos
		LEFT JOIN  OJDT t2 ON t2.TransId  = t0.DocTransId	--Join cabeçalho lançamentos ctbeis
		LEFT JOIN (SELECT TransId, Account, ProfitCode AS OcrCode, Debit, Credit -- Join cabeçalho lançamentos ctbeis
					FROM JDT1 WHERE Account <> '1.01.03.01.01') t3 ON t3.TransId = t2.TransId   --Filtrar créditos dos forncedores
		
	WHERE		t1.Canceled = 'N' -- Verifica se o documento foi cancelado
		AND t1.CashSum + t1.CheckSum + t1.TrsfrSum > 0 -- Verifica se a baixa de compensação (sem financeiro)
		AND t1.DocType <> 'A' -- Verifica se o documento é orinada de conta ou fonrcedor / cliente
		AND (t0.InvType <> 13 AND t0.InvType <> 14) -- Verifica se o documento é de nota fiscal ou devolucao de nota fiscal

) t0
	INNER JOIN OACT t1 ON t1.AcctCode = t0.AcctCode