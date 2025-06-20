import React, { useState } from 'react';
import {
	LinearProgress,
	Button,
	Grid,
	TextField,
	IconButton,
	Popover,
} from '@mui/material';
import Truncate from 'react-truncate';
import { makeStyles } from '@mui/styles';
import { useDispatch, useSelector } from 'react-redux';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import NumberFormat from 'react-number-format';

import Nui from '../../util/Nui';
import Reagent from './Reagent';
import Tooltip from './Tooltip';
import { DurationToTime } from '../../util/Parser';
import Moment from 'react-moment';
import { getItemImage } from '../Inventory/item';
import { useTheme } from '@mui/material/styles';

const useStyles = makeStyles((theme) => ({
	customRippleGreen: {
		color: "rgba(0, 36, 0, 0.9)",
	  },
	  customRippleRed: {
		color: "rgba(219, 40, 9, 0.9)",
	  },
	  wrapper: {
		width: "100%",
		height: "100%",
		background: "rgba(18, 18, 28, 0.7)",
		//backdropFilter: "blur(5px)",
		borderRadius: 8,
		padding: 16,
		display: "flex",
		flexDirection: "column",
		justifyContent: "center",
		alignItems: "space-between",
		boxShadow: "0 4px 15px rgba(0, 0, 0, 0.15)",
		border: "1px solid rgba(255, 255, 255, 0.05)",
	  },
	  TopContainer: {
		flex: "0 0 25%",
		width: "100%",
		display: "flex",
		justifyContent: "space-between",
		alignItems: "center",
		flexDirection: "row",
		overflow: "hidden",
	  },
	  topLeftContainer: {
		padding: 8,
		flex: "0 0 20%",
		height: "100%",
		display: "flex",
		justifyContent: "center",
		alignItems: "center",
		borderRadius: 8,
		boxShadow: "0 4px 15px rgba(0, 0, 0, 0.15)",
		border: "1px solid rgba(255, 255, 255, 0.05)",
		background: "rgba(0, 0, 0, 0.2)",
	  },
	  topRightContainer: {
		padding: 8,
		flex: "0 0 78%",
		height: "100%",
		display: "flex",
		justifyContent: "flex-start",
		alignItems: "space-between",
		borderRadius: 8,
		flexDirection: "column",
		overflow: "hidden",
	  },
	  toprightTopContainer: {
		overflow: "hidden",
		flex: "0 0 35%",
		fontSize: 20,
		fontWeight: 700,
		display: "flex",
		justifyContent: "flex-start",
		alignItems: "center",
	  },
	  toprightMiddleContainer: {
		display: "flex",
		alignItems: "center",
		flex: "0 0 25%",
	  },
	  toprightBottomContainer: {
		display: "flex",
		alignItems: "center",
		flex: "0 0 25%",
	  },
	  mainImage: {
		height: "auto",
		width: "100%",
		objectFit: "contain",
	  },
	  MiddleContainer: {
		flex: "0 0 65%",
		width: "100%",
		paddingTop: 16,
		display: "flex",
		overflow: "hidden",
	  },
	  middleCraftContainer: {
		backgroundColor: "rgba(0, 0, 0, 0.2)",
		borderRadius: 8,
		padding: 16,
		height: "auto",
		width: "100%",
		display: "flex",
		flexDirection: "column",
		overflow: "hidden",
		border: "1px solid rgba(255, 255, 255, 0.05)",
	  },
	  middleTopContainer: {
		display: "flex",
		flex: "0 0 15%",
		fontSize: 16,
		fontWeight: 800,
		justifyContent: "flex-start",
		alignItems: "flex-start",
		marginBottom: 12,
	  },
	  middleBottomContainer: {
		flex: "1 1 auto",
		overflow: "auto",
		display: "grid",
		gridTemplateColumns: "repeat(4, 15%)",
		justifyContent: "center",
		gap: 24,
		gridAutoRows: "max-content",
		"&::-webkit-scrollbar": {
		  width: 6,
		},
		"&::-webkit-scrollbar-thumb": {
		  background: "rgba(255, 255, 255, 0.1)",
		  borderRadius: 3,
		  transition: "background ease-in 0.15s",
		},
		"&::-webkit-scrollbar-thumb:hover": {
		  background: "rgba(255, 255, 255, 0.2)",
		},
		"&::-webkit-scrollbar-track": {
		  background: "transparent",
		},
	  },
	  BottomContainer: {
		flex: "0 0 10%",
		width: "100%",
		paddingTop: 16,
		display: "flex",
		flexDirection: "row",
		justifyContent: "space-between",
		alignItems: "center",
		overflow: "hidden",
	  },
	  bottomLeftContainer: {
		flex: "0 0 15%",
		boxShadow: "inset 0 0 4vh rgba(0, 0, 0, 0.3)",
		height: "100%",
		display: "flex",
		alignItems: "center",
		justifyContent: "space-evenly",
		borderRadius: 8,
		background: "rgba(18, 18, 28, 0.5)",
		border: "1px solid rgba(255, 255, 255, 0.05)",
	  },
	  bottomRightContainer: {
		flex: "0 0 83%",
		height: "100%",
		display: "flex",
		justifyContent: "space-evenly",
		alignItems: "center",
	  },
	  craftButton: {
		width: "100%",
		height: "100%",
		color: "white",
		fontWeight: 600,
		"&:hover": {
		  backgroundColor: "rgba(1, 77, 0, 0.8)",
		},
		borderRadius: 8,
		textTransform: "none",
		display: "flex",
		justifyContent: "center",
		fontSize: 14,
	  },
	  inputText: {
		textAlign: "center",
		height: "100%",
		fontSize: 16,
		width: "75%",
		fontWeight: 600,
	  },
	  popoverContainer: {
		pointerEvents: "none",
	  },
	  paperContainer: {
		padding: 15,
		border: `1px solid rgba(255, 255, 255, 0.1)`,
		borderRadius: 8,
		//backdropFilter: "blur(10px)",
		background: "rgba(18, 18, 28, 0.95)",
		boxShadow: "0 10px 25px rgba(0, 0, 0, 0.3)",
		"&.rarity-1": {
		  borderLeft: `3px solid ${theme.palette.rarities.rare1}`,
		},
		"&.rarity-2": {
		  borderLeft: `3px solid ${theme.palette.rarities.rare2}`,
		},
		"&.rarity-3": {
		  borderLeft: `3px solid ${theme.palette.rarities.rare3}`,
		},
		"&.rarity-4": {
		  borderLeft: `3px solid ${theme.palette.rarities.rare4}`,
		},
		"&.rarity-5": {
		  borderLeft: `3px solid ${theme.palette.rarities.rare5}`,
		},
	  },
	  cooldownText: {
		color: "white",
		marginRight: 4,
		fontWeight: 700,
		fontSize: 14,
	  },
}));

const Recipe = ({ index, recipe, cooldown }) => {
	const classes = useStyles();
	const dispatch = useDispatch();
	const hidden = useSelector((state) => state.app.hidden);
	const items = useSelector((state) => state.inventory.items);
	const bench = useSelector((state) => state.crafting.bench);
	
	const action = useSelector((state) => state.crafting.actionString);
	const crafting = useSelector((state) => state.crafting.crafting);
	const myCounts = useSelector((state) => state.crafting.myCounts);
	const theme = useTheme();

	const [qty, setQty] = useState(1);

	const [resultEl, setResultEl] = useState(null);
	const resultOpen = Boolean(resultEl);
	const resultTPOpen = (event) => {
		setResultEl(event.currentTarget);
	};

	const resultTPClose = () => {
		setResultEl(null);
	};

	const hasReagents = () => {
		let reagents = {}; 
		recipe.items.map((item, k) => {
			if (!Boolean(reagents[item.name]))
				reagents[item.name] = item.count * qty;
			else reagents[item.name] += item.count * qty;
		});

		for (const item in reagents) {
			if (!Boolean(myCounts[item]) || reagents[item] > myCounts[item])
				return false;
		}

		return true;
	};

	const craft = async () => {
		if (Boolean(crafting)) return;

		try {
			let res = await (
				await Nui.send('Crafting:Craft', {
					bench,
					qty,
					result: recipe.id,
				})
			).json();

			if (res) {
				Nui.send('FrontEndSound', 'SELECT');
				dispatch({
					type: 'SET_CRAFTING',
					payload: {
						recipe: recipe.id,
						start: Date.now(),
						time: recipe.time * qty,
					},
				});
			} else {
				Nui.send('FrontEndSound', 'DISABLED');
			}
		} catch (err) {}
	};

	const cancel = async () => {
		let res = await (await Nui.send('Crafting:Cancel')).json();
		if (res) {
			Nui.send('FrontEndSound', 'BACK');
			dispatch({
				type: 'END_CRAFTING',
			});
		} else {
			Nui.send('FrontEndSound', 'DISABLED');
		}
	};

	const onQtyChange = (change) => {
		if (Boolean(recipe.cooldown)) return;

		if ((change < 0 && qty <= 1) || (change > 1 && qty >= 99)) return;
		setQty(qty + change);
	};
	//console.log("RECIPE DATA", recipe);
	//console.log("ITEM DATA", items[recipe.result.name])

	const getRarityColor = (rarity) => {
		switch (rarity) {
		  case 1:
			return theme.palette.rarities.rare1;
		  case 2:
			return theme.palette.rarities.rare2;
		  case 3:
			return theme.palette.rarities.rare3;
		  case 4:
			return theme.palette.rarities.rare4;
		  case 5:
			return theme.palette.rarities.rare5;
		  default:
			return theme.palette.rarities.rare1;
		}
	};

	const craftItemData = items[recipe.result.name];
	//console.log("RARITY", craftItemData.rarity )
	return (
		<div className={classes.wrapper}>
			
			<Popover
				className={classes.popoverContainer}
				classes={{
					paper: `${classes.paperContainer} rarity-${
						craftItemData?.rarity
					}`,
				}}
				open={resultOpen && !hidden}
				anchorEl={resultEl}
				anchorOrigin={{
					vertical: 'center',
					horizontal: 'right',
				}}
				transformOrigin={{
					vertical: 'top',
					horizontal: 'center',
				}}
				onClose={resultTPClose}
				disableRestoreFocus
			>
				<Tooltip
					item={items[recipe.result.name]}
					count={recipe.result.count}
				/>
			</Popover>

			<div className={classes.TopContainer}>
				<div className={classes.topLeftContainer}
				style={{
					boxShadow: `inset 0 0 4vh ${getRarityColor(craftItemData.rarity)}`,
				}}		  
				>
					<img 
						className={classes.mainImage}
						src={getItemImage(
							recipe.result,
							items[recipe.result.name],
						)}
						onMouseEnter={resultTPOpen}
						onMouseLeave={resultTPClose}
					/>
				</div>

				<div className={classes.topRightContainer} >
					<div className={classes.toprightTopContainer} 
					style={{
						color: `${getRarityColor(craftItemData?.rarity)}`,
					}}
					>
						<Truncate lines={1} >
							{craftItemData.label}
						</Truncate>
					</div>
					{/* <div className={classes.toprightSpaceContainer} >

					</div> */}
					<div className={classes.toprightMiddleContainer} >
						<div style={{
							color: "white",
							marginRight: "0.5vh",
							fontWeight: 700,
							fontSize: "1.5vh",
						}} >
							Yield:
						</div>
						<div style={{
							color: `${getRarityColor(craftItemData?.rarity)}`, 
							fontWeight: 700,
							fontSize: "1.5vh",
						}} >
							{recipe.result.count * qty}pcs
						</div>
					</div>

					<div className={classes.toprightBottomContainer} >
						<div style={{
							color: "white",
							marginRight: "0.5vh",
							fontWeight: 700,
							fontSize: "1.5vh",
						}} >
							Crafting Time:
						</div>
						<div style={{
							color: `${getRarityColor(craftItemData?.rarity)}`, 
							fontWeight: 700,
							fontSize: "1.5vh",
						}} >
							{recipe.time > 0 ? (
								<span>
									{(recipe.time * qty) / 1000}sec
								</span>
		 					) : (
		 						<span>
									Instant
								</span>
		 					)}
							
						</div>
					</div>
					
					{Boolean(recipe.cooldown) && Boolean(cooldown) && cooldown > Date.now() && (
					<span style={{
						color: "white",
						marginRight: "0.5vh",
						fontWeight: 700,
						fontSize: "1.5vh",
					}}>
						Craft Available{' '}
						<Moment date={cooldown} interval={1000} fromNow />
					</span>
				)}
				</div>
           	 </div>
            <div className={classes.MiddleContainer}>
                <div className={classes.middleCraftContainer}>
					<div className={classes.middleTopContainer}>
						Items Required
					</div>
					<div className={classes.middleBottomContainer}>
						{recipe.items.map((item, k) => {
		 					return (
		 						<Reagent
									key={`${recipe.name}-${index}-ing-${k}`}
	 								item={item}
									qty={qty}
		 						/>
		 					);
		 				})}
					</div>
                </div>
            </div>
            <div className={classes.BottomContainer}>
                <div className={classes.bottomLeftContainer}>
		 			{/* {!Boolean(recipe.cooldown) && ( */}
						<span style={{
							display: "flex",
							alignItems: "center",
							justifyContent: "space-evenly",
							width: "100%",
							//height: "100%",
						}}>
							<IconButton
								disabled={
									Boolean(recipe.cooldown) ||
									qty <= 1
								}
								onClick={() => onQtyChange(-1)}
								style={{
									fontSize: "1.5vh",
								}}
							>
								<FontAwesomeIcon
									icon={['fas', 'minus']}
								/>
							</IconButton>

							<div className={classes.inputText} >
								{qty}
							</div>

							<IconButton
								disabled={
									Boolean(recipe.cooldown) ||
									qty >= 99
								}
								onClick={() => onQtyChange(1)}
								style={{
									fontSize: "1.5vh",
								}}
							>
								<FontAwesomeIcon
									icon={['fas', 'plus']}
								/>
							</IconButton>
						</span>
					{/* )} */}
                </div>
                <div className={classes.bottomRightContainer}>
					{Boolean(crafting) && crafting.recipe === recipe.id && recipe.time > 0 ? (
						<Button
							disabled={!Boolean(crafting)}
							className={classes.craftButton}
							onClick={cancel}
							style={{
								boxShadow: 'inset 0 0 4vh rgba(110, 9, 9, 0.8)', 
							}}
							TouchRippleProps={{
								classes: { ripple: classes.customRippleRed },
							}}
						>
							
							{/* <span className={classes.progressTxt}>
								{`${Math.floor(crafting.progress)}%`}
							</span>
						
							
							<LinearProgress
								color="info"
								className={classes.progressBar}
								value={Math.floor(crafting.progress)}
								variant="determinate"
								style={{ width: '100%', marginTop: '5px' }} 
							/>  */}
						
							Cancel
						</Button>
						) : (
						<Button
							className={classes.craftButton}
							onClick={craft}
							TouchRippleProps={{
								classes: { ripple: classes.customRippleGreen },
							}}
							disabled={
								Boolean(crafting) ||
								!hasReagents() ||
								(Boolean(recipe.cooldown) &&
								Boolean(cooldown) &&
								cooldown > Date.now())
							}
							style={  
								Boolean(crafting) || !hasReagents() || (Boolean(recipe.cooldown) && Boolean(cooldown) && cooldown > Date.now()) ? 
								{
									boxShadow: 'inset 0 0 4vh rgba(48, 48, 48, 0.8)',
								} : {
									boxShadow: 'inset 0 0 4vh rgba(2, 191, 0, 0.8)', 
								}
							}
						>
							{Boolean(crafting) || !hasReagents() ? (
								"Cannot Craft"
								// <FontAwesomeIcon icon={['fas', 'ban']} />
							) : (
								"Craft"
								// <FontAwesomeIcon icon={['fas', 'hammer']} />
							)}
						</Button>
					)}
                </div>
            </div>
		</div>
	);
};

export default Recipe;
