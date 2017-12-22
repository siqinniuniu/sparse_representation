function [A] = OMPdenoise(D, X, Im_sigma)
% Orthogonal matching pursuit  (greed algorithm)   
%  
%   min_{a}  ||a||_0        subject to  || x_{ij} - D a ||_2 <= C*sigma^2
%   C與x 維度有關係
%
% input :
% X 原始訊號當作column排成的訊號矩陣 X = [x_1, x_2, x_3, ..., x_p];
% D 訊號字典 (DCT, harr wavelet 等等)
% L a的非零元個數
% output :
% a 表示係數
% 如果 || x - D a ||_2 < C*sigma^2 則跳出迴圈
waitBarOn = 1;
if (waitBarOn)
    counterForWaitBar = size(X,2);
    h = waitbar(0,'OMP In Process ...');
end
[n, p] = size(X);
C = n*1.2;
k = size(D, 2);
A = sparse(k, p);
L = ceil(n/2);
%先將D 中每一個atom單位化
norm_D = zeros(size(D));
for i = 1 : k
    norm_D(:,i) = D(:,i)/norm(D(:,i));
end

for i = 1 : p
    %initailize
    R = X(:, i);
    Phi = [];
    atom_ind = [];
    for j = 1 : L
        g = abs(norm_D'*R);
        [val, ind] = max(g); %找出內積絕對值最大的分量
        atom_ind = [atom_ind, ind];% atom_ind 表示在第i次疊代以前，所有已經用過的 atom index。
        Phi = [Phi, norm_D(:,ind)]; %Phi 用來儲存，先前所選擇過的 atom
        
        %%% 將 X(:, j) 分解成與 R(Phi) 空間 與 垂直 R(Phi)的空間 的直和(direct sum)。(Phi 矩陣的Range space 記做 R(Phi))
        PinvPhi = pinv(Phi);
        temp_coe = PinvPhi*X(:,i); %計算將 X(:,j) 投影到 R(Phi) 空間使得|| X(:,i) - Phi*(temp_coe)|| 最小的係數
        P = Phi*PinvPhi; %P 為投影到 R(Phi) 空間的正交投影矩陣  P = Phi*inv(Phi'*Phi)*Phi'
        R = X(:,i) - P*X(:,i); %R 為剩下的殘差向量，R需滿足與 已經用過的 atom 均互相垂直
        
        if norm(R)^2 < C*Im_sigma^2 %如果剩下的殘差量的 norm 平方 小於 C sigma^2，則跳出迴圈
            break;
        end
    end
    %將係數填回 係數矩陣Ａ
    A(atom_ind, i) = temp_coe;
    if (waitBarOn)
        waitbar(i/counterForWaitBar);
    end
end
if (waitBarOn)
    close(h);
end
end