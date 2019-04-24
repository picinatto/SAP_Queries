SELECT 
		t1.DocNum, 
		t1.DocType, 
		t1.DocDate,
		NULL AS CardCode,
		NULL AS CardName,
		t1.DocTotal,
		t1.TransId AS OJDT_Doc,
		CASE
			WHEN t1.CashAcct IS NOT NULL THEN t1.CashAcct
			WHEN t2.CheckAct IS NOT NULL THEN t2.CheckAct
			WHEN t1.BankAcct IS NOT NULL THEN t1.BankAcct
										 ELSE t1.TrsfrAcct
			END AS PayAcct,
		t0.LineId,
		t0.AcctCode,
		t0.SumApplied,
		t0.OcrCode

FROM	VPM4 t0
		INNER JOIN OVPM t1 ON t1.DocNum	  = t0.DocNum		--JOIN CABECALHO
		LEFT JOIN  VPM1 t2 ON t2.DocNum	  = t0.DocNum		--JOIN CHEQUE

WHERE 
			t1.Canceled = 'N' 
		AND t1.DocType  = 'A'
		AND LEFT(t0.AcctCode,7)<>'1.01.01'