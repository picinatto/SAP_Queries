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
			WHEN t1.CashAcct IS NOT NULL THEN t1.CashAcct
			WHEN t1.CheckSum > 0		 THEN '1.01.01.03.01'
			WHEN t1.BankAcct IS NOT NULL THEN t1.BankAcct
			ELSE t1.TrsfrAcct
			END AS PayAcct,
		t0.AcctCode,
		t0.SumApplied,
		t0.OcrCode

FROM	RCT4 t0
		INNER JOIN ORCT t1 ON t1.DocNum	  = t0.DocNum	--Join cabeçalho recebimentos

WHERE 
			t1.Canceled = 'N' 
		AND t1.DocType  = 'A'
		AND LEFT(t0.AcctCode,7) <> '1.01.01' -- Excluir transferências entre contas da empresa
		AND LEFT(t0.AcctCode,10)<>'1.01.03.07' -- Exclui transferências de valores do acerto dos vendedores