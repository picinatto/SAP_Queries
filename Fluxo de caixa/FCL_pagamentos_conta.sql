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

FROM	VPM4 t0
		INNER JOIN OVPM t1 ON t1.DocNum	  = t0.DocNum --Join cabeçalho

WHERE 
			t1.Canceled = 'N' 
		AND t1.DocType  = 'A'
		AND LEFT(t0.AcctCode,7)<>'1.01.01' --Filtrar transferências entre contas da empresa