unit uProdutoRepository;

interface

uses
  System.Generics.Collections, MVCFramework.ActiveRecord, uProdutoModel;

type
  TProdutoRepository = class
  public
    class function GetAll: TObjectList<TProduto>;
    class function GetById(const AId: Integer): TProduto;
    class procedure Add(const AProd: TProduto);
    class procedure Update(const AProd: TProduto);
    class procedure Delete(const AId: Integer);
  end;

implementation

{ TProdutoRepository }

class function TProdutoRepository.GetAll: TObjectList<TProduto>;
begin
  Result := TMVCActiveRecord.All<TProduto>;
end;

class function TProdutoRepository.GetById(const AId: Integer): TProduto;
begin
  Result := TMVCActiveRecord.GetByPK<TProduto>(AId);
end;

class procedure TProdutoRepository.Add(const AProd: TProduto);
begin
  // se Id=0, Postgres SERIAL gera e o DMVC preenche via RETURNING
  AProd.Insert;
end;

class procedure TProdutoRepository.Update(const AProd: TProduto);
begin
  AProd.Update;
end;

class procedure TProdutoRepository.Delete(const AId: Integer);
var
  P: TProduto;
begin
  P := TMVCActiveRecord.GetByPK<TProduto>(AId);
  try
    if Assigned(P) then
      P.Delete;
  finally
    P.Free;
  end;
end;

end.

