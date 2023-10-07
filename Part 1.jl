using JuMP
using Gurobi

#Sets
Warehouses=["Seattle-S","Denver-S","St.Louis-S","Atlanta-S","Philadelphia-S","Seattle-L","Denver-L","St.Louis-L","Atlanta-L","Philadelphia-L"];
Customers=["Northwest","Southwest","Upper Midwest","Lower Midwest","Northeast","Southeast"];
Periods=["2007","2008","2009","2010","2011"];

I = length(Customers) #No. of zones/customers
J = length(Warehouses) #No. of potential warehouses/DCs
P = length(Periods) #No. of periods

#Data
h = 
[
320000 576000 1036800 1866240 1866240;
200000 360000 648000  1166400 1166400;
160000 288000 518400  933120  933120;
220000 396000 712800  1283040 1283040;
350000 630000 1134000 2041200 2041200;
175000 315000 567000  1020600 1020600
] #Demand

f = [300000 250000 220000 220000 240000 500000 420000 375000 375000 400000] #Fixed cost of potential warehouses

b = 0.2 #Variable cost of potential warehouses

v = [2000000 2000000 2000000 2000000 2000000 4000000 4000000 4000000 4000000 4000000] #Capcity of large/small warehouses

c=[
2 2.5 3.5 4 5 5.5;
2.5 2.5 2.5 3 4 4.5;
3.5 3.5 2.5 2.5 3 3.5;
4 4 3 2.5 3 2.5;
4.5 5 3 3.5 2 4;
2 2.5 3.5 4 5 5.5;
2.5 2.5 2.5 3 4 4.5;
3.5 3.5 2.5 2.5 3 3.5;
4 4 3 2.5 3 2.5;
4.5 5 3 3.5 2 4
]

model = Model(Gurobi.Optimizer)
@variable(model, x[j=1:J,p=1:P] >= 0, Bin);
@variable(model, y[i=1:I,j=1:J,p=1:P] >= 0, Int);
@variable(model, a[j=1:J,p=1:P] >= 0, Bin);
    


@objective(model, Min, sum(sum(f[j]*x[j,p] for j=1:J) for p=1:P)
    + sum(sum(sum(b*y[i,j,p] for i=1:I) for j=1:J) for p=1:P)
    + sum(sum(sum(((c[j,i]-3)/4)*y[i,j,p] for i=1:I) for j=1:J) for p=1:P)
    + sum(sum(475000*x[j,p]+0.165*sum(y[i,j,p] for i=1:I) for j=1:J) for p=1:P));


@constraint(model,[i=1:I, p=1:P], sum(y[i,j,p] for j=1:J)== h[i,p]);
@constraint(model,[j=1:J, p=1:P], sum(y[i,j,p] for i=1:I)<= v[j]*x[j,p]);


@constraint(model,[j=1:J, p=1:3], sum(a[j,p] for p=p:p+2)<= 1);#
@constraint(model,[j=1:J, p=4], sum(a[j,p] for p=p:p+1)<= 1);#
@constraint(model,[j=1:J, p=5],a[j,p]<=1)

@constraint(model,[j=1:J, p=1:3], 3*a[j,p]<= sum(x[j,p] for p=p:p+2));
@constraint(model,[j=1:J, p=4], 2*a[j,p]<= sum(x[j,p] for p=p:p+1));


@constraint(model,[j=1:J, p=3:P], sum(a[j,q] for q=p-2:p)>= x[j,p]);
@constraint(model,[j=1:J, p=2],   sum(a[j,q] for q=p-1:p)>= x[j,p]);
@constraint(model,[j=1:J, p=1],   a[j,p]>= x[j,p]);


@constraint(model,[p=1:P,j=1:5], x[j,p] + x[j+5,p] <= 1)
@constraint(model,[p=1:P,j=6:10], x[j,p] + x[j-5,p] <= 1)

optimize!(model)

if termination_status(model) == MOI.OPTIMAL
    println("RESULTS:")
    println("Objective = $(objective_value(model))")
    for p=1:P
        println("In year ", Periods[p], ":")
        for j=1:J
            if (value(a[j,p]) == 1)
                if (value(x[j,p])==1)
                    println("Lease coefficient = ",value(a[j,p]))
                    println("Warehouse ", Warehouses[j], " is serving customer:")
                    for i=1:I
                        if (value(y[i,j,p]) > 0)
                            println(Customers[i],", Demand satisfied = ",value(y[i,j,p]))
                        end
                    end
                end
            end
            if (value(a[j,p]) == 0)
                if (value(x[j,p])==1)
                    println("Lease coefficient = ",value(a[j,p]))
                    println("Warehouse ", Warehouses[j], " is serving customer:")
                    for i=1:I
                        if (value(y[i,j,p]) > 0)
                            println(Customers[i],", Demand satisfied = ",value(y[i,j,p]))
                        end
                    end
                end
            end    
        end
    end
else
    println("No solution")
end